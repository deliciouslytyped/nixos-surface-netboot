sketch:

Use extra-container to create a container running the services necessary for pxe boot;
connect container interface to physical lan interface, and connect surface to boot.

```
sudo ip link add name pxebr type bridge
sudo ip link set pxebr up
sudo ip link set eth0 master pxebr
sudo ip link set ve-ipxesurf master pxebr

sudo env NIX_PATH=nixpkgs=channel:nixos-unstable:"$NIX_PATH" extra-container create ./containers.nix -r
sudo ip link set ve-ipxesurf master pxebr #needs to be rerun every time the container gets reset
```

files:
- containers.nix - wrapper
- installer.nix - install image specific stuff
- ipxeserv.nix - container networking config mostly
- kernel.nix - meat ; kernel config and patches for surface stuff
- linux-surface.json - points to upstream linux-surface repo where we get kernel patches from, see comment in kernel.nix for updating
- netboot_server.nix - more meat; based off cleverca22's code
- propagate_config.nix - stuff for making the installed nixos similar to the installer image (we just copy in the configuration)

