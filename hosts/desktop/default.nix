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
  ];

  drivers.nvidia.enable = false;
}