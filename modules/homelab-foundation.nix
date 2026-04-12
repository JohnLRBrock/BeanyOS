{ config, pkgs, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  networking.firewall.enable = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = lib.mkDefault [ ];
  networking.firewall.allowedUDPPorts = lib.mkDefault [ ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  system.autoUpgrade = {
    enable = true;
    operation = "switch";
    allowReboot = false;
    dates = "weekly";
    randomizedDelaySec = "45min";
    flake = lib.mkDefault "github:JohnLRBrock/BeanyOS#homelab-laptop";
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    code-cursor
    age
  ];

  system.stateVersion = "24.05";
}
