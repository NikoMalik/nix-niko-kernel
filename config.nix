{
  lib,
  amdgpu ? true,
  nouveau ? false,
  # false drops TTM and every driver selecting it (amdgpu radeon nouveau i915 xe qxl vmwgfx vboxvideo hibmc)
  ttm ? true,
  polly ? false,
  bore ? true,
  cachy ? true,
  native ? true,
  x86Level ? 1,
  hz ? 1000,
  # "full" | "lazy" | "none"
  preempt ? "full",
  preemptDynamic ? preempt == "full",
  nohzFull ? true,
  extraConfig ? { },
}:

# 7.2 only allows preempt=none as a static model (see 7.2.10-preempt_none.patch)
assert preempt == "none" -> !preemptDynamic;
assert !ttm -> !amdgpu && !nouveau;
assert lib.elem x86Level [ 1 2 3 4 ];

let
  inherit (lib.kernel) yes no module freeform;

  cfg = {
  LOCALVERSION = freeform "-niko";

  CACHY = if cachy then yes else no;
  SCHED_BORE = if bore then yes else no;

  LTO_NONE = no;
  LTO_CLANG_THIN = yes;

  X86_NATIVE_CPU = if native then yes else no;
  GENERIC_CPU = if native then no else yes;

  HZ = freeform (toString hz);

  HZ_PERIODIC = no;
  NO_HZ_IDLE = if nohzFull then no else yes;
  NO_HZ_FULL = if nohzFull then yes else no;
  NO_HZ = yes;
  NO_HZ_COMMON = yes;

  PREEMPT_DYNAMIC = if preemptDynamic then yes else no;
  PREEMPT = if preempt == "full" then yes else no;
  PREEMPT_LAZY = if preempt == "lazy" then yes else no;
  PREEMPT_NONE = if preempt == "none" then yes else no;
  PREEMPT_VOLUNTARY = no;

  CC_OPTIMIZE_FOR_PERFORMANCE = no;
  CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;

  TCP_CONG_CUBIC = module;
  DEFAULT_CUBIC = no;
  TCP_CONG_BBR = yes;
  DEFAULT_TCP_CONG = freeform "bbr";
  NET_SCH_FQ_CODEL = module;
  NET_SCH_FQ = yes;
  DEFAULT_FQ_CODEL = no;
  DEFAULT_FQ = yes;

  TRANSPARENT_HUGEPAGE_MADVISE = no;
  TRANSPARENT_HUGEPAGE_ALWAYS = yes;

  LRU_GEN = yes;
  LRU_GEN_ENABLED = yes;

  EXPERT = yes;
  SCHED_CLUSTER = yes;
  SCHED_SMT = yes;
  USER_NS = yes;
  NET_RX_BUSY_POLL = yes;
  BUSY_POLL = yes;
  PER_VMA_LOCK = yes;

  DRM_NOUVEAU = if nouveau then module else no;

  # keep BPF and tracing fully working
  FTRACE = yes;
  FUNCTION_TRACER = yes;
  FUNCTION_GRAPH_TRACER = yes;
  DYNAMIC_FTRACE = yes;
  FTRACE_SYSCALLS = yes;
  STACK_TRACER = yes;
  SCHED_TRACER = yes;
  STACKTRACE = yes;
  USER_STACKTRACE_SUPPORT = yes;
  KPROBES = yes;
  KPROBE_EVENTS = yes;
  UPROBE_EVENTS = yes;
  DEBUG_FS = yes;
  BPF = yes;
  BPF_SYSCALL = yes;
  BPF_JIT = yes;
  BPF_EVENTS = yes;
  DEBUG_INFO_BTF = yes;

  DEBUG_MEMORY_INIT = no;
  SHRINKER_DEBUG = no;
  BLK_DEBUG_FS = no;
  MODULE_DEBUGFS = no;
  CMA_DEBUGFS = no;
  NVME_TARGET_DEBUGFS = no;
  VFIO_DEBUGFS = no;
  ATH5K_DEBUG = no;
  ATH9K_COMMON_DEBUG = no;
  ATH9K_DEBUGFS = no;
  ATH10K_DEBUG = no;
  ATH10K_DEBUGFS = no;
  ATH11K_DEBUG = no;
  ATH11K_DEBUGFS = no;
  ATH12K_DEBUG = no;
  ATH12K_DEBUGFS = no;
  IWLWIFI_DEBUG = no;
  IWLWIFI_DEBUGFS = no;
  RTW88_DEBUG = no;
  RTW89_DEBUG = no;
  RTW89_DEBUGMSG = no;
  NETFS_DEBUG = no;
  NFS_DEBUG = no;
  SUNRPC_DEBUG = no;
  CIFS_DEBUG = no;
  DLM_DEBUG = no;
  VIRTIO_DEBUG = no;
  DM_DEBUG = no;
  DM_DEBUG_BLOCK_MANAGER_LOCKING = no;
  MLX4_DEBUG = no;
  DYNAMIC_DEBUG_CORE = no;
  DYNAMIC_DEBUG = no;
  DEBUG_BUGVERBOSE = no;
  SECURITY_DMESG_RESTRICT = no;
  SECURITY_PERF_EVENTS_RESTRICT = no;
  STACKTRACE_BUILD_ID = no;
  SCSI_IPR_TRACE = no;
  TRACE_GPU_MEM = no;
  SLAB_FREELIST_RANDOM = no;
  SLAB_FREELIST_HARDEN = no;
  SHUFFLE_PAGE_ALLOCATOR = no;
  KFENCE = no;
  DEBUG_WX = no;
  SCHEDSTATS = no;
  PROFILING = no;
  NUMA_BALANCING = no;
  ACPI_DEBUG = no;
  PM_DEBUG = no;
  PM_SLEEP_DEBUG = no;
  PAGE_POISONING = no;
  SLUB_DEBUG = no;
  SND_DEBUG = no;
  MITIGATION_SLS = no;
}
// builtins.listToAttrs (
  map (n: lib.nameValuePair "HZ_${toString n}" (if n == hz then yes else no)) [ 100 250 300 500 600 750 1000 ]
)
// lib.optionalAttrs nohzFull {
  CONTEXT_TRACKING_FORCE = no;
  NO_HZ_FULL_NODEF = yes;
  CONTEXT_TRACKING = yes;
}
// lib.optionalAttrs (!native) {
  X86_64_VERSION = freeform (toString x86Level);
}
// lib.optionalAttrs polly {
  POLLY_CLANG = yes;
}
// lib.optionalAttrs (!amdgpu) {
  DRM_AMDGPU = no;
  DRM_AMDGPU_SI = no;
  DRM_AMDGPU_CIK = no;
  DRM_AMDGPU_USERPTR = no;
  DRM_AMD_DC = no;
  DRM_AMD_DC_FP = no;
  DRM_AMD_DC_SI = no;
  HSA_AMD = no;
  DRM_RADEON = no;
}
# TTM is only selectable thanks to the ttm patch, and only once nothing selects it
// lib.optionalAttrs (!ttm) {
  DRM_TTM = no;
  DRM_TTM_HELPER = no;
  DRM_I915 = no;
  DRM_XE = no;
  DRM_QXL = no;
  DRM_VMWGFX = no;
  DRM_VBOXVIDEO = no;
  DRM_HISI_HIBMC = no;
}
// extraConfig;
in
lib.mapAttrs (_: lib.mkForce) cfg
