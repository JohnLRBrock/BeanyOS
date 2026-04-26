{ lib, ... }:

{
  services.caddy = {
    enable = lib.mkDefault true;
    openFirewall = false;

    globalConfig = ''
      auto_https disable_redirects
    '';

    # Catch-all on private interfaces; firewall rules enforce trust boundaries.
    virtualHosts.":80" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8096

        header {
          X-Content-Type-Options "nosniff"
          Referrer-Policy "strict-origin-when-cross-origin"
          X-Frame-Options "SAMEORIGIN"
        }
      '';
    };
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = lib.mkDefault [ 80 ];
  networking.firewall.interfaces."wlp3s0".allowedTCPPorts = lib.mkDefault [ 80 ];
}
