{pkgs, lib, ...}: {
  #nixpkgs.config.allowUnfree = true;
  imports = [ (import ./kernel.nix {}) ];
  services.mingetty.autologinUser = lib.mkForce "nixos";
  }
