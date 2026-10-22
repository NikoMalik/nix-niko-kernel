# niko-kernel (NixOS)

CachyOS 7.2 bore kernel, packaged for NixOS. amdgpu is on by default; the TTM
patch makes `DRM_TTM`/`DRM_TTM_HELPER` selectable so they can be forced off
together with amdgpu in the `-noamdgpu` variant.

## Layout

- `flake.nix` — outputs the kernel package, `linuxPackages-niko`, a NixOS module and an overlay
- `kernel.nix` — the `buildLinux` derivation, pulls the pre-sauced CachyOS source tarball
- `config.nix` — kernel config as `structuredExtraConfig` (bore, O3, BBR, full tick/preempt, amdgpu off)

## First build: fill two things

1. **Source hash.** `kernel.nix` ships `hash = lib.fakeHash`. Run a build, copy
   the real hash from the error, paste it in:
   ```
   nix build .#niko-kernel
   # error: hash mismatch ... got: sha256-....
   ```
   Or prefetch:
   ```
   nix store prefetch-file --name cachyos-7.2.10-1.tar.gz \
     https://github.com/CachyOS/linux/releases/download/cachyos-7.2.10-1/cachyos-7.2.10-1.tar.gz
   ```

2. **cachy config hash.** `kernel.nix` also fetches the base config
   (`linux-cachyos-bore/config` pinned at `configCommit`,with `hash = lib.fakeHash`. Fill it the same way as
   the source hash. It is dropped into `arch/x86/configs/niko_defconfig` and used
   as the base; `structuredExtraConfig` (`config.nix`) layers on top.

## Use in NixOS

Flake-based config:
```nix
{
  inputs.niko-kernel.url = "path:/home/niko/textcodes/nix-niko-kernel";
  # or github:NikoMalik/nix-niko-kernel once pushed

  outputs = { nixpkgs, niko-kernel, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ niko-kernel.nixosModules.default ./configuration.nix ];
    };
  };
}
```

Or pick packages directly:
```nix
boot.kernelPackages =
  niko-kernel.legacyPackages.x86_64-linux.linuxPackages-niko;
```

## amdgpu

On by default. To build without it (NVIDIA box, skips the big amdgpu/DC
compile), use the `-noamdgpu` variant:
```
nix build .#niko-kernel-noamdgpu
```
or `mkKernel { amdgpu = false; }`.

## polly

Off by default. `mkKernel { polly = true; }` sets `POLLY_CLANG=y`. Needs a
Polly-capable LLVM — the default nixpkgs `clang` has no Polly, so `-mllvm -polly`
fails there; supply an `llvmPackages` built with Polly before enabling. Polly
also has a track record of miscompiling large codebases, so leave it off unless
you know the LLVM has it.

## Toolchain

clang + ThinLTO only (no GCC — the patches are clang-only), config has
`LTO_CLANG_THIN=y`. The full LLVM toolchain is wired in `llvm.nix` (pattern from
nixpkgs#129806 / lovesegfault's linux-lto):

- `stdenvLLVM` — a `clangUseLLVM` stdenv (pure LLVM, no GNU binutils) with the
  kernel `makeFlags` extended by `ltoMakeflags`.
- `ltoMakeflags` — `LLVM=1 LLVM_IAS=1` plus explicit `CC/LD/AR/NM/STRIP/OBJCOPY/
  OBJDUMP/READELF` and the `HOST*` equivalents all pointing at LLVM, so the host
  side is clang too (not GCC).
- `kernelModuleLLVMOverride` — wraps `linuxPackagesFor` so out-of-tree modules
  (nvidia, zfs, …) build with the same LLVM flags and their `gcc` Makefile
  hardcodes are rewritten to `cc`. `linuxPackages-niko` already goes through it.

To pin a clang version, override `llvmPackages` in `llvm.nix`
(`pkgs.pkgsBuildHost.llvmPackages` → e.g. `llvmPackages_20`).


## Notes

- NVIDIA is out-of-tree (`hardware.nvidia`), independent of this kernel; nouveau is off. // and use rss-stat patch for nvidia(from niko-patches)
