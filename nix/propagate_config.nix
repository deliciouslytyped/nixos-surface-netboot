#The goal is for the installer to install a system similar to the one it was built with.
{pkgs, ...}:{
#  environment.pathsToLink = let
#      config = pkgs.symlinkJoin { name = "config"; paths = [ ./. <nixpkgs> ]; }; 
##          script = writeShellScript "withconf" ''
##            NIX_PATH=nixpkgs=${<nixpkgs>}:"$NIX_PATH"
##            '';
##        in  [ "${config}" script ];
#    in  [ config "${config}"  ];

  # Meh import convention inconsistens with netboot_server.nix
  #imports = [ <nixpkgs/nixos/modules/profiles/clone-config.nix> ];
#  installer.cloneConfig = false;
  installer.cloneConfigIncludes = [ "(import ./kernel.nix {})" ]; #lol this sux
  boot.postBootCommands = ''
    mkdir -p /etc/nixos
    pushd /etc/nixos
    chmpd +w -R .
    cp -r '${./.}'/* .
    popd
    '';
  }


