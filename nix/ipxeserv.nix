let
  ports = [ 53 67 68 69 80 ];
in
args@{hostAddress, localAddress, ...}: {
  networking.firewall.allowedTCPPorts = ports;
  networking.firewall.allowedUDPPorts = ports;
  containers.ipxesurf = {
    privateNetwork = true; 
    inherit hostAddress; 
    inherit localAddress;
    autoStart = false;

    config = {...}: {
      imports = [ (import ./netboot_server.nix { hostAddress = localAddress; hostSubnetRoot = "10.250.0"; }) ];

      netboot_server.network.wan = "eth0";
      netboot_server.network.lan = "eth0";


      networking.interfaces.eth0.ipv4.routes = [ { address = "10.250.0.0"; prefixLength = 24; } ];
      networking.firewall = { 
        enable = false;
        allowPing = true;

        allowedTCPPorts = ports;
        allowedUDPPorts = ports;
        };

      };
    forwardPorts = 
      (builtins.map (p: {containerPort = p; hostPort = p; protocol = "tcp";}) ports) ++
      (builtins.map (p: {containerPort = p; hostPort = p; protocol = "udp";}) ports);
    };
  }
