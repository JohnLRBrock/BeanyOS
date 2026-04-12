{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware.nix
    ./storage.nix
  ];

  networking.hostName = "homelab-laptop";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.john = {
    isNormalUser = true;
    description = "John Brock";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = [ ];
  };

  sops.defaultSopsFile = ../../secrets/default.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
