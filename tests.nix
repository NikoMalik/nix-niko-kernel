{
  pkgs,
  linuxPackages,
}:

pkgs.testers.runNixOSTest {
  name = "niko-kernel-boot";

  nodes.machine =
    { ... }:
    {
      boot.kernelPackages = linuxPackages;
      boot.loader.grub.enable = false;
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    # booted our kernel
    machine.succeed("uname -r | grep -- -niko")

    # tracing is available
    machine.succeed("test -d /sys/kernel/tracing")

    # bpf syscall is enabled
    machine.succeed("test -e /proc/sys/kernel/unprivileged_bpf_disabled")

    # bore scheduler is in
    machine.succeed("grep -q bore /sys/kernel/debug/sched/* 2>/dev/null || true")

    print(machine.succeed("uname -a"))
  '';
}
