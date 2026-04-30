{ config, pkgs, lib, ... }:

let
  hcfg = config.homelab.qbittorrent;
  webuiPort = 18080;

  inherit (builtins) concatStringsSep isAttrs isString;
  inherit (lib.generators) toINI mkKeyValueDefault mkValueStringDefault;

  gendeepINI = toINI {
    mkKeyValue =
      let
        sep = "=";
      in
      k: v:
      if isAttrs v then
        concatStringsSep "\n" (
          lib.filter isString (
            lib.collect isString (
              lib.mapAttrsRecursive (
                path: value:
                "${lib.escape [ sep ] (concatStringsSep "\\" ([ k ] ++ path))}${sep}${
                  lib.replaceStrings [ "\n" ] [ "\\n" ] (mkValueStringDefault { } value)
                }"
              ) v
            )
          )
        )
      else
        mkKeyValueDefault { } sep k v;
  };

  serverCfg = {
    LegalNotice.Accepted = true;
    Preferences = {
      General.Locale = "en";
      Downloads = {
        SavePath = "/mnt/data-bulk/torrents/downloads";
        TempPathEnabled = true;
        TempPath = "/mnt/data-bulk/torrents/incomplete";
      };
      WebUI = {
        Address = "127.0.0.1";
        Port = toString webuiPort;
        Username = "admin";
        Password_PBKDF2 = "@QB_PBKDF2@";
      };
    };
  };

  baseConf = pkgs.writeText "qBittorrent-base.conf" (gendeepINI serverCfg);
in
{
  options.homelab.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent-nox with a public Web UI hostname";
    publicHostname = lib.mkOption {
      type = lib.types.str;
      default = "brew.kaijutea.party";
    };
    torrentingPort = lib.mkOption {
      type = lib.types.port;
      default = 51413;
    };
  };

  config = lib.mkIf hcfg.enable {
    sops.secrets."qbittorrent-webui-password-pbkdf2" = {
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d /mnt/data-bulk/torrents 0755 qbittorrent qbittorrent -"
      "d /mnt/data-bulk/torrents/incomplete 0755 qbittorrent qbittorrent -"
      "d /mnt/data-bulk/torrents/downloads 0755 qbittorrent qbittorrent -"
    ];

    services.qbittorrent = {
      enable = true;
      openFirewall = false;
      webuiPort = null;
      torrentingPort = hcfg.torrentingPort;
      extraArgs = [ "--confirm-legal-notice" ];
    };

    systemd.services.qbittorrent = {
      wants = [ "sops-install-secrets.service" ];
      after = [ "sops-install-secrets.service" ];
      serviceConfig.ReadWritePaths = [
        "/mnt/data-bulk/torrents"
        "/mnt/data-bulk/torrents/incomplete"
        "/mnt/data-bulk/torrents/downloads"
      ];
      serviceConfig.ExecStartPre = lib.mkForce [
        (
          let
            profileDir = config.services.qbittorrent.profileDir;
            secret = config.sops.secrets."qbittorrent-webui-password-pbkdf2".path;
            confPath = "${profileDir}/qBittorrent/config/qBittorrent.conf";
          in
          "${pkgs.writeShellScript "qbittorrent-install-conf" ''
            set -euo pipefail
            ${pkgs.coreutils}/bin/install -Dm600 ${baseConf} "${confPath}"
            ${pkgs.replace-secret}/bin/replace-secret @QB_PBKDF2@ "${secret}" "${confPath}"
          ''}"
        )
      ];
    };

    networking.firewall = {
      allowedTCPPorts = [ hcfg.torrentingPort ];
      allowedUDPPorts = [ hcfg.torrentingPort ];
    };

    services.caddy.virtualHosts.${hcfg.publicHostname}.extraConfig = ''
      reverse_proxy 127.0.0.1:${toString webuiPort}
    '';
  };
}
