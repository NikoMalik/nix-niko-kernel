{
  lib,
  amdgpu ? true,
  polly ? false,
}:

let
  inherit (lib.kernel) yes no module freeform;
in
{
  LOCALVERSION = freeform "-niko";

  CACHY = yes;
  SCHED_BORE = yes;

  LTO_NONE = no;
  LTO_CLANG_THIN = yes;

  X86_NATIVE_CPU = yes;
  GENERIC_CPU = no;

  HZ_300 = no;
  HZ_1000 = yes;
  HZ = freeform "1000";

  HZ_PERIODIC = no;
  NO_HZ_IDLE = no;
  CONTEXT_TRACKING_FORCE = no;
  NO_HZ_FULL_NODEF = yes;
  NO_HZ_FULL = yes;
  NO_HZ = yes;
  NO_HZ_COMMON = yes;
  CONTEXT_TRACKING = yes;

  PREEMPT_DYNAMIC = yes;
  PREEMPT = yes;
  PREEMPT_VOLUNTARY = no;
  PREEMPT_LAZY = no;
  PREEMPT_NONE = no;

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

  DRM_NOUVEAU = no;

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
  DRM_TTM = no;
  DRM_TTM_HELPER = no;
}
