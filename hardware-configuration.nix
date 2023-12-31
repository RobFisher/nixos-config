# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.resumeDevice = "/dev/disk/by-uuid/e449f71e-0fa1-450e-ad0b-f47fadb1c15d";

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/16b1a7ed-ad57-405c-82e5-547fa0b1ccaf";
      fsType = "ext4";
      options = [ "noatime" ];
    };

  boot.initrd.luks.devices."luks-2722a2e1-e381-4c03-9bf7-a45e74567d16".device = "/dev/disk/by-uuid/2722a2e1-e381-4c03-9bf7-a45e74567d16";
  boot.initrd.luks.devices."luks-a4516463-77e1-4f4c-9225-73d93419e9c7".device = "/dev/disk/by-uuid/a4516463-77e1-4f4c-9225-73d93419e9c7";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3C3B-F790";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/e449f71e-0fa1-450e-ad0b-f47fadb1c15d"; }
    ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp170s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
