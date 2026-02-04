{ ... }:

{
  # nas
  fileSystems."/mnt/nas" = {
    device = "//192.168.0.123/Mihaita";
    fsType = "cifs";

    options = [
      "username=mihaita"
      "password=azuredragon"  # todo: credentials file
      "uid=ankhangel"
      "gid=users"
      "iocharset=utf8"
      "vers=3.1.1"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
    ];
  };
}
