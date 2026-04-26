{ lib, ... }:

{
  services.caddy = {
    enable = lib.mkDefault true;
    openFirewall = false;

    globalConfig = ''
      auto_https disable_redirects
    '';

    virtualHosts."jellyfin.homelab" = {
      # Bind only to trusted interfaces/addresses.
      listenAddresses = [
        "127.0.0.1"
        "100.89.105.95"
        "192.168.0.179"
      ];

      serverAliases = [
        "100.89.105.95"
        "192.168.0.179"
      ];

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

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = lib.mkDefault [ 80 443 ];
  networking.firewall.interfaces."wlp3s0".allowedTCPPorts = lib.mkDefault [ 80 443 ];
}
