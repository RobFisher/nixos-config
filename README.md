A simple configuration for my NixOS machines.

(Currently there is only one, a Framework laptop.)

# Useful commands
## Updating
This is a way to see what packages will be made before commiting to an update.

```shell
cd <directory containing this repo>
nix flake update --commit-lock-file
nixos-rebuild build --flake .

# see what is about to change
nvd diff /run/current-system result

# if happy, switch to the updated packages
sudo nixos-rebuild switch
```

Consider rebooting if the kernel has been updated.

If unhappy with the update, one option is to simply avoid switching until ready; another is to use Git
to reset to the previous commit.

