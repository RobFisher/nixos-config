# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, inputs, ... }:

# Workaround for broken Electron
# Remove this when this fix makes it to unstable: https://github.com/NixOS/nixpkgs/issues/302457
# Track it here: https://nixpk.gs/pr-tracker.html?pr=302544
# note that I seem to be replacing version 27 with 28 here (unlike the published workaround)
let
  myOverlay = self: super: {
      electron_27 = pkgs.electron_28.overrideAttrs
        (oldAttrs: rec {

          buildCommand =
            let
              electron-unwrapped = pkgs.electron_28.passthru.unwrapped.overrideAttrs (oldAttrs: rec {
                postPatch = builtins.replaceStrings [ "--exclude='src/third_party/blink/web_tests/*'" ] [ "--exclude='src/third_party/blink/web_tests/*' --exclude='src/content/test/data/*'" ] oldAttrs.postPatch;
              });
            in
            ''
              gappsWrapperArgsHook
              mkdir -p $out/bin
              makeWrapper "${electron-unwrapped}/libexec/electron/electron" "$out/bin/electron" \
                "''${gappsWrapperArgs[@]}" \
                --set CHROME_DEVEL_SANDBOX $out/libexec/electron/chrome-sandbox

              ln -s ${electron-unwrapped}/libexec $out/libexec
            '';
        });
      electron = pkgs.electron.overrideAttrs
        (oldAttrs: rec {
          buildCommand =
            let
              electron-unwrapped = pkgs.electron.passthru.unwrapped.overrideAttrs (oldAttrs: rec {
                postPatch = builtins.replaceStrings [ "--exclude='src/third_party/blink/web_tests/*'" ] [ "--exclude='src/third_party/blink/web_tests/*' --exclude='src/content/test/data/*'" ] oldAttrs.postPatch;
              });
            in
            ''
              gappsWrapperArgsHook
              mkdir -p $out/bin
              makeWrapper "${electron-unwrapped}/libexec/electron/electron" "$out/bin/electron" \
                "''${gappsWrapperArgs[@]}" \
                --set CHROME_DEVEL_SANDBOX $out/libexec/electron/chrome-sandbox

              ln -s ${electron-unwrapped}/libexec $out/libexec
            '';
        });
  };
in

{
  # remove when electron is working again
  nixpkgs.overlays = [ myOverlay ];

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;

  boot.initrd.luks.devices."luks-a4516463-77e1-4f4c-9225-73d93419e9c7".device = "/dev/disk/by-uuid/a4516463-77e1-4f4c-9225-73d93419e9c7";

  # sleep then hibernate
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  systemd.tmpfiles.rules = [
    "d /mnt/media 1755 root root"
    "d /mnt/backup 1755 root root"
  ];

  # set up sops for secrets
  sops.defaultSopsFile = ./secrets/example.yaml;
  sops.age.sshKeyPaths = [ "/home/rob/.ssh/id_ed25519" ];
  # This is using an age key that is expected to already be in the filesystem
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  # This will generate a new key if the key specified above does not exist
  sops.age.generateKey = true;

  # now specify the secrets that will be placed in /run/secrets
  # test with e.g. sudo cat /run/secrets/my_secret
  sops.secrets.example_key = {};
  sops.secrets.my_secret = {};

  networking.hostName = "thorin"; # Define your hostname.

  # filesystem options for SSD optimisation
  services.fstrim.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;

  networking.firewall = {
   # wg-quick up configures the firewall properly but NetworkManager does not,
   # so if we want the convenience of turning the VPN on and off with the tray icon
   # we fix the rpfilter problem here.
   extraCommands = ''
     ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
     ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
   '';
   extraStopCommands = ''
     ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
     ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
   '';
  };

  services.zerotierone.enable = true;

  # Network diagnostics tool
  programs.mtr.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "uk";

  #fonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.rob = {
    isNormalUser = true;
    description = "rob";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kate
    #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    xsel # command line X clipboard manipulation (used by Helix)
    wezterm
    cifs-utils
    nvd
    nushellFull
    nushellPlugins.formats
    vim
    git
    helix
    lsd
    bat
    ripgrep
    neofetch
    rclone
    logseq
    keepassxc
    tigervnc
    imlib2Full # for feh
    feh
    mplayer
    kmplayer
    nixd
    wireguard-tools
  ];

  fileSystems."/mnt/network-shared-files" = {
    device = "packmule.super:/mnt/packmule_pool/backup/samwise_rob_home/network-shared-files";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" ];
  };

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = "--delete-older-than 30d";
    dates = "weekly";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" "nixos-config=/etc/nixos/configuration.nix" "/nix/var/nix/profiles/per-user/root/channels" ];
  environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;
}
