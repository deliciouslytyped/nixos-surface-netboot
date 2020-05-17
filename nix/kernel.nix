#TODO nix-module-build for evla chekcing and stuff
{  kver ? "4.19" }: {pkgs, lib, ...}: 

let
  kver' = builtins.replaceStrings [ "." ] [ "_" ] kver;
  kernel = (self: super:
    let
      # Can do pinning via this json file
      # nix-shell -I nixpkgs=channel:nixos-unstable -p nix-prefetch-github --run "nix-prefetch-github linux-surface linux-surface > linux-surface.json"
      patches = self.fetchFromGitHub { inherit (self.lib.importJSON ./linux-surface.json) owner repo rev sha256;};
      mapDir = f: p: builtins.attrValues (builtins.mapAttrs (k: _: f p k) (builtins.readDir p));
      patch = dir: file: { name = file; patch = dir + "/${file}"; };
      upstreamPatches = mapDir patch (patches + "/patches/${kver}");
    in {
      "linux_${kver'}" = super."linux_${kver'}".override { argsOverride = {
        #Filter the file into the format extraConfig expects; namely remove comments (?) and CONFIG_ #TODO ? https://github.com/NixOS/nixpkgs/blob/4756e2eb0c3e712c7a815bc7417d3c10dce072a8/pkgs/os-specific/linux/kernel/manual-config.nix#L8
        extraConfig = let #TODO
          orig_conf = "${patches}/configs/surface-${kver}.config";
          nix_conf = self.runCommand "filtered-config" {} ''grep -Ev "(^#)|^$" ${orig_conf} | sed "s/CONFIG_//" | sed "s/[ ]*#.*$//" | sed "s/=/ /" > "$out"'';
            in (builtins.readFile nix_conf) + "\nSERIAL_DEV_BUS y\nSERIAL_DEV_CTRL_TTYPORT y"; #need to enable deps because nixos kernel config handling sux #TODO fix upstream nixpkgs (big)

        kernelPatches = upstreamPatches;
        };};
      });

in  {
  nixpkgs.overlays = [ kernel ];
  boot.kernelPackages = pkgs."linuxPackages_${kver'}";
  }
