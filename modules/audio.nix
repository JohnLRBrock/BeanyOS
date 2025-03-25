# Audio configuration
{ config, pkgs, audio, inputs, ... }:

let
  unstablePkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    system = builtins.currentSystem;
    config = { allowUnfree = true; };
  };
in 
{
  environment.systemPackages = with pkgs; [
    # ~~ Music production software ~~
    reaper
    qpwgraph
    alsa-scarlett-gui
    transcribe
    musescore

    # ~ Instrument plugins ~ 
    # - Synths - 
    vital
    dexed
    surge-XT
    # helm
    # zynaddsubfx
    # odin2

    # - Drums - 
    geonkick
    # drumgizmo
    # hydrogen
    # pianoteq.standard-8

    # - Misc Instruments - 
    decent-sampler

    # ~ Audio plugins ~
    # - Plugin Packs -
    lsp-plugins
    calf 
    # distrho-ports
    guitarix

    # - Individual Packs
    # eq10q
    dragonfly-reverb
    delayarchitect
    # x42-plugins
    # x42-gmsynth
    # x42-avldrums
    # FIL-plugins
    # airwindows-lv2
    # stone-phaser
    # autotalent
    # talentedhack
    # ninjas2
    # sfizz
    
    # Support for Windows VST2/VST3 plugins
    yabridge 
    yabridgectl
    # When installing iLok with wine you might get some errors complaining about the version of Windows 7
    # - You can fix that issue by running winecfg in the console and then upgrading to Windows 10.
    # After doing that I got an error that said something like `pnputil.exe failed blah blah 9009`.
    # - The trick is that you need a very specific version of the iLok License Manager (5.6.1): https://www.filehorse.com/download-ilok-license-manager-64/73904/
    wineWowPackages.stable
  ];

  # Disable pusleaudio when enabling sound with pipewire.
  services.pulseaudio.enable = false; 
  services.pipewire = {
    enable = true;

    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this

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
  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL="hpet", GROUP="audio"
  '';
  musnix.enable = true;
}