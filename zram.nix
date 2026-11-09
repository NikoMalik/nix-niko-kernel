{ lib, ... }:
{
  zramSwap = {
    enable = true;
    algorithm = lib.mkDefault "lz4kdr zstd";
    memoryPercent = lib.mkDefault 100;
    priority = lib.mkDefault 100;
  };

  systemd.services.zram-recompress = {
    description = "Recompress idle zram pages";
    unitConfig.ConditionPathExists = "/sys/block/zram0/recompress";
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    script = ''
      echo 900 > /sys/block/zram0/idle
      echo type=idle > /sys/block/zram0/recompress
    '';
  };

  systemd.timers.zram-recompress = {
    description = "Recompress idle zram pages periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";
      OnUnitActiveSec = "15min";
    };
  };
}
