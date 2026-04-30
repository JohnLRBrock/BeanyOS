{ lib, ... }:

{
  services.caddy = {
    enable = lib.mkDefault true;
    openFirewall = false;
    email = "johnlrbrock@gmail.com";

    globalConfig = ''
      auto_https disable_redirects
    '';

  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = lib.mkDefault [ 80 ];
  networking.firewall.interfaces."wlp3s0".allowedTCPPorts = lib.mkDefault [ 80 ];
}
