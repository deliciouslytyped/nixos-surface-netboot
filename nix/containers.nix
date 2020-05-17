args@{config, ...}: {
  imports = [
    (import ./ipxeserv.nix ({
      hostAddress = "10.250.0.1";
      localAddress = "10.250.0.12";
      } // args))
    ];

#  networking.nat.enable = true;
#  networking.nat.internalInterfaces = ["ve-+"];
#  networking.nat.externalInterface = if (config.isVM) then "eth0" else "wlp3s0";
#  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];
  }
