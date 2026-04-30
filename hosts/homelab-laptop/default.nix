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
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEPIoFGNZR3pTDpDAc30WfKVDuq1wJ8M/NsRM0ginTXW john@homelab-laptop"
    ];
  };

  services.openssh.settings.PasswordAuthentication = false;

  homelab.publicEdge = {
    enable = true;
    hostname = "latenight.kaijutea.party";
    enableDDNS = false;
  };

  homelab.qbittorrent.enable = true;

  sops.defaultSopsFile = ../../secrets/default.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
}
