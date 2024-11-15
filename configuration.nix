# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

# let
#   unstablePkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
#     system = builtins.currentSystem;
#     config = { allowUnfree = true; };
#   };
# in 
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    # drivers = [ pkgs.brlaser pkgs.cups-brother-hll2350dw ];
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
    openFirewall = true;
  };

  sound.enable = true;

  # Disable pusleaudio when enabling sound with pipewire.
  hardware.pulseaudio.enable = false; 
  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    wireplumber.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    # media-session.enable = true;
  };
  # Realtime privileges for audio production
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-";    value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-";    value = "99"; }
    { domain = "@audio"; item = "nofile";  type = "soft"; value = "99999"; }
    { domain = "@audio"; item = "nofile";  type = "hard"; value = "524288"; }
  ];
  musnix.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.john = {
    isNormalUser = true;
    description = "John Brock";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox
  programs.firefox.enable = true;

  # Install git
  programs.git = {
    enable = true;
    # userName = "JohnLRBrock";
    # userEmail = "johnlrbrock@gmail.com";
    config = {
      init.defaultBranch = "main";
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-25.9.0" "openssl-1.1.1w" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gh
    github-desktop
    vim 
    vscode
    obsidian

    discord

    # ~~ Music production software ~~
    reaper
    qpwgraph
    alsa-scarlett-gui
    transcribe
    # Instrument plugins
    vital
    helm
    zynaddsubfx
    dexed
    odin2
    geonkick
    surge-XT
    drumgizmo
    hydrogen
    # Audio plugins
    distrho
    calf
    eq10q
    lsp-plugins
    x42-plugins
    x42-gmsynth
    x42-avldrums
    dragonfly-reverb
    guitarix
    FIL-plugins
    delayarchitect
    airwindows-lv2
    stone-phaser
    # autotalent
    talentedhack
    ninjas2
    sfizz
    
    # Support for Windows VST2/VST3 plugins
    yabridge 
    yabridgectl
    wineWowPackages.stable
    # When installing iLok with wine you might get some errors complaining about the version of Windows 7
    # - You can fix that issue by running winecfg in the console and then upgrading to Windows 10.
    # After doing that I got an error that said something like `pnputil.exe failed blah blah 9009`.
    # - The trick is that you need a very specific version of the iLok License Manager (5.6.1): https://www.filehorse.com/download-ilok-license-manager-64/73904/

    spotify
    spotify-qt

    # qbittorrent
    zoom-us

    # unstablePkgs.code-cursor
  ];

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
  system.stateVersion = "24.05"; # Did you read the comment?

}
