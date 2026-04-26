{ ... }:

let
  slowDas = [
    "nofail"
    "x-systemd.mount-timeout=300"
  ];
in
{
  fileSystems."/mnt/data-fast" = {
    device = "/dev/disk/by-uuid/ce497894-677b-49bd-9785-2e0c4ee344fd";
    fsType = "ext4";
    options = [ "defaults" ] ++ slowDas;
  };

  fileSystems."/mnt/data-bulk" = {
    device = "/dev/disk/by-uuid/92607dcf-a503-4c33-89fa-a71e634a5f93";
    fsType = "ext4";
    options = [ "defaults" ] ++ slowDas;
  };
}
