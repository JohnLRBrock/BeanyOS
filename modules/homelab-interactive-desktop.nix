{ config, pkgs, lib, ... }:

{
  boot.supportedFilesystems = lib.mkDefault [ "ntfs" ];

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat";
      accelSpeed = "-10.0";
    };
    touchpad.accelProfile = "flat";
  };

  stylix = {
    enable = true;
    image = ../wallpapers/green-fish.jpg;
    polarity = "dark";
    opacity.terminal = 0.9;
  };

  programs.firefox.enable = true;

  users.users.john.extraGroups = lib.mkAfter [ "video" ];
}
