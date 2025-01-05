# Desktop configuration
{ config, pkgs, audio, ... }:

let
  unstablePkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    system = builtins.currentSystem;
    config = { allowUnfree = true; };
  };
in 
{
  imports = [
    ./hardware.nix
    # ../../../modules/audio.nix
    # ../../../modules/nvidia-drivers.nix
  ];
    xnixpkgs.config.allowUnfree = true;

    # Enable nvidia graphics card
    # hardware = {
    #   graphics.enable = true;
    #   # opengl.enable = true;
    #   nvidia = {
    #     modesetting.enable = true;
    #     open = false;
    #     powerManagement.enable = true;
    #     powerManagement.finegrained = true;
    #     nvidiaSettings = true;
    #     prime = {
    #       offload = {
    #         enable = true;
    #         enableOffloadCmd = true;
    #       };
    #       # sync.enable = true;
    #       nvidiaBusId = "PCI:10:0:0";
    #     };

    #     # package = config.boot.kernelPackages.nvidiaPackages.stable;
    #   };
    # };
    # services.xserver.videoDrivers = [:nvidia"];

    # attempted to fix reboot graphical errors
    # boot.kernelModules = ["nvidia" "nvidia_modeset" ];
    # boot.extraModprobeConfig = ''
    #     options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/tmp
    # '';
    # boot.kernelPackages = pkgs.linuxPackages_latest; # 6.11.7
}