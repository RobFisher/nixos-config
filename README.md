A simple configuration for my NixOS machines.

(Currently there is only one, a Framework laptop.)

# Useful commands
## Updating
This is a way to see what packages will be made before commiting to an update.

```shell
cd <directory containing this repo>
nix flake update --commit-lock-file
nh os build

# if happy, switch to the updated packages
nh os switch
```

Consider rebooting if the kernel has been updated.

If unhappy with the update, one option is to simply avoid switching until ready; another is to use Git
to reset to the previous commit.

# Manual steps
## Wireguard
The wg-quick config file is not included in this repo.

Recreate it and use these commands to add the VPN to the Network Manager tray.

    nmcli connection import type wireguard file homevpn.conf
    nmcli connection modify homevpn autoconnect no

## Zerotier One

    sudo zerotier-cli join <network id>
