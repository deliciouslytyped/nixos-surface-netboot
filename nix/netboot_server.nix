{hostAddress, hostSubnetRoot}:
{ lib, config, pkgs, ... }:
with lib;
let

  netboot = let
    build = (import (pkgs.path + "/nixos/lib/eval-config.nix") {
      system = "x86_64-linux";
      modules = [
        (pkgs.path + "/nixos/modules/installer/netboot/netboot-minimal.nix")
        ./installer.nix
        ./propagate_config.nix
        ];
      }).config.system.build;
      in pkgs.symlinkJoin {
        name = "netboot";
        paths = with build; [ netbootRamdisk kernel netbootIpxeScript ];
        };

  ipxe' = pkgs.ipxe.overrideDerivation (drv: {
    installPhase = ''
      ${drv.installPhase}
      make $makeFlags bin-x86_64-efi/ipxe.efi bin-i386-efi/ipxe.efi
      cp -v bin-x86_64-efi/ipxe.efi $out/x86_64-ipxe.efi
      cp -v bin-i386-efi/ipxe.efi $out/i386-ipxe.efi
      '';
    });
  
  tftp_root = pkgs.runCommand "tftproot" {} ''
    mkdir -pv $out
    cp -vi ${ipxe'}/undionly.kpxe $out/undionly.kpxe
    cp -vi ${ipxe'}/x86_64-ipxe.efi $out/x86_64-ipxe.efi
    cp -vi ${ipxe'}/i386-ipxe.efi $out/i386-ipxe.efi
    '';
  
  nginx_root = pkgs.runCommand "nginxroot" {} ''
    mkdir -pv $out
    cat <<EOF > $out/boot.php
    #!ipxe
    chain netboot/netboot.ipxe
    EOF
    ln -sv ${netboot} $out/netboot
    '';
  
  cfg = config.netboot_server;

in {

  options = {
    netboot_server = {
      network.wan = mkOption {
        type = types.str;
        description = "the internet facing IF";
        };
      network.lan = mkOption {
        type = types.str;
        description = "the netboot client facing IF";
        };
      };
    };

  config = {
    services = {
      nginx = {
        enable = true;
        virtualHosts = {
          "${hostAddress}" = {
            root = nginx_root;
            };
          };
        };
      #TODO docs
      dhcpd4 = {
        interfaces = [ cfg.network.lan ];
        enable = true;
        extraConfig = ''
          option arch code 93 = unsigned integer 16;
          subnet ${hostSubnetRoot}.0 netmask 255.255.255.0 {
            option domain-search "localnetboot";
            option subnet-mask 255.255.255.0;
            option broadcast-address ${hostSubnetRoot}.255;
            option routers ${hostAddress};
            option domain-name-servers ${hostAddress}, 8.8.8.8, 8.8.4.4;
            range ${hostSubnetRoot}.100 ${hostSubnetRoot}.200;
            next-server ${hostAddress};
            if exists user-class and option user-class = "iPXE" {
              filename "http://${hostAddress}/boot.php?mac=''${net0/mac}&asset=''${asset:uristring}&version=''${builtin/version}";
            } else {
              if option arch = 00:07 {
                filename = "x86_64-ipxe.efi";
              } else {
                filename = "undionly.kpxe";
              }
            }
          }
          '';
        };
      atftpd = {
        enable = true;
        root = tftp_root;
        extraOptions =  [  "--verbose=5" ];
        };
      bind = {
        enable = true;
        cacheNetworks = [ "${hostSubnetRoot}.0/24" "127.0.0.0/8" ];
        };
      };
    };

  }
