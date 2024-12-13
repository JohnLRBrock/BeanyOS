# Shared configuration
{ config, pkgs, audio, ... }:

let
  unstablePkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    system = builtins.currentSystem;
    config = { allowUnfree = true; };
  };
in 
{
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
  services.xserver = { 
    enable = true;
    # Enable the GNOME Desktop Environment.
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Styling options
  stylix = {
    enable = true;
    image = ../wallpapers/green-fish.jpg;
    polarity = "dark";
    opacity.terminal = 0.9;
  };

  # Enable peer to peer file syncing
  # You can confirm Syncthing runs by visiting http://127.0.0.1:8384/ and authenticating using the credentials below.
  # Further configuration: https://wiki.nixos.org/wiki/Syncthing
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    settings = {
      devices = {
        "desktop" = { id = "PKXKSII-ALSROEH-ICJASET-XCSGCJV-AX7VU5I-26BS3KI-EUSZGJT-44TMTQE"; };
        "laptop" = { id = "6KJLABY-Z2FT63T-RXUT5PI-AQNE3FY-ELWG2CF-XEY6QSM-REHB2KN-EFIHUQG"; };
        "phone" = { id = "ZX5FH5U-J2QA7R6-BV7TXD2-Q5LI6E2-DSLPKZW-4WKS3U4-HNVCEIS-TUOSQQG"; };
      };
      folders = {
        "Sync" = {
          path = "~/Shared/Sync/";
          devices = [ "desktop" "laptop" "phone" ];
        };
        "Obsidian Vault" = {
          path = "~/Shared/Obsidian Vault/";
          devices = [ "desktop" "laptop" "phone" ];
        };
        "Picture Backup" = {
          path = "~/Shared/Pictures/Backup";
          devices = [ "desktop" "laptop" ];
        };
        "Camera" = {
          path = "~/Shared/Pictures/Camera";
          devices = [ "desktop" "laptop" "phone" ];
        };
      };
    };
      # user = "myuser";
      # password = "mypassword";
  };
  # Don't create default ~/Sync folder
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true"; 

  # Enable hotkeys and keyswaps
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            capslock = "overload(control, esc)";
            esc = "capslock";
          };
          otherlayer = {};
        };
        extraConfig = '''';
      };
    };
  };

  # Enable CUPS to print documents 
  services.printing.enable = true;

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_HL-L2350DW_series";
        deviceUri = "ipp://192.168.0.161:631/ipp";
        model = "everywhere";
      }
    ];
    ensureDefaultPrinter = "Brother_HL-L2350DW_series";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    # Disable mouse acceleration
    mouse = {
      accelProfile = "flat";
      accelSpeed = "-10.0";
    };

    touchpad = {
      accelProfile = "flat";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.john = {
    isNormalUser = true;
    description = "John Brock";
    extraGroups = [ "networkmanager" "wheel" "audio" "realtime" "video"];
    packages = with pkgs; [
    ];
  };

  # Install firefox
  programs.firefox.enable = true;

  # Install Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  # Create package exceptions
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "electron-25.9.0" "openssl-1.1.1w" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    neovim
    vscode
    kitty
    code-cursor
    nodejs_23
    gh
    github-desktop

    syncthing
    syncthing-tray
    obsidian
    kdePackages.filelight

    discord
    slack

    spotify
    spotify-tray
    spotify-qt

    qbittorrent
    # A tool to create bootable live USB drives from ISO images.
    ventoy-full
    # unetbootin
    zoom-us

    # Simple bar for Wayland/Hyprland
    # waybar
    # (waybar.overrideAttrs (oldAttrs: {
    #   mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
    # }))
    # More complex bar for Wayland/Hyprland
    # eww 
    # Notifications
    # dunst <-
    # libnotify <-
    # Wallpaper manager
    # hyprpaper
    # swaybg
    # wpaperd
    # mpvpaper
    # swww <-
    # App launder
    # wofi
    # rofi-wayland <-
    # bemenu
    # fuzzel
    # tofi
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
