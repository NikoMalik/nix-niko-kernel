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
    # the recompression runs inside the write() to /sys/block/zram0/recompress,
    # so SCHED_IDLE on this process keeps zstd off cores anything else wants
    serviceConfig = {
      Type = "oneshot";
      CPUSchedulingPolicy = "idle";
      CPUWeight = "idle";
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
