{ config, lib, ... }:

let
  cfg = config.homelab.publicEdge;
  parts = lib.splitString "." cfg.hostname;
  host = builtins.head parts;
  zone = lib.concatStringsSep "." (builtins.tail parts);
in
{
  options.homelab.publicEdge = {
    enable = lib.mkEnableOption "public Jellyfin access via Caddy";
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "latenight.kaijutea.party";
    };
    enableDDNS = lib.mkEnableOption "ddclient updates for dynamic WAN IP";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      services.caddy.virtualHosts.${cfg.hostname}.extraConfig = ''
        reverse_proxy 127.0.0.1:8096
      '';
    })

    (lib.mkIf cfg.enableDDNS {
      sops.secrets."ddclient-namecheap" = { };

      services.ddclient = {
        enable = true;
        protocol = "namecheap";
        username = zone;
        server = "dynamicdns.park-your-domain.com";
        ssl = true;
        usev4 = "webv4, webv4=ipify-ipv4";
        zone = zone;
        domains = [ host ];
        secretsFile = config.sops.secrets."ddclient-namecheap".path;
      };
    })
  ];
}
