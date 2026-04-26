{ lib, ... }:

{
  services.jellyfin = {
    enable = lib.mkDefault true;
    openFirewall = false;
  };

  # Keep Jellyfin private to trusted interfaces only.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = lib.mkDefault [ 8096 ];
  networking.firewall.interfaces."wlp3s0".allowedTCPPorts = lib.mkDefault [ 8096 ];
}
