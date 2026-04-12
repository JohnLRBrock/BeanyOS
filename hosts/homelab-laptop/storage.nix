{ ... }:

let
  slowDas = [
    "nofail"
    "x-systemd.mount-timeout=300"
  ];
in
{
  fileSystems."/mnt/data-fast" = {
    device = "/dev/disk/by-uuid/823E22F73E22E43F";
    fsType = "ntfs3";
    options = [
      "uid=1000"
      "gid=100"
      "umask=002"
    ] ++ slowDas;
  };

  fileSystems."/mnt/data-bulk" = {
    device = "/dev/disk/by-uuid/92607dcf-a503-4c33-89fa-a71e634a5f93";
    fsType = "ext4";
    options = [ "defaults" ] ++ slowDas;
  };
}
