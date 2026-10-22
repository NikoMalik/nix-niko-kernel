# niko-kernel (NixOS)

CachyOS 7.2 bore kernel, packaged for NixOS. amdgpu is on by default; the TTM
patch makes `DRM_TTM`/`DRM_TTM_HELPER` selectable so they can be forced off
together with amdgpu in the `-noamdgpu` variant.

## Layout

- `flake.nix` — outputs the kernel package, `linuxPackages-niko`, a NixOS module and an overlay
- `kernel.nix` — the `buildLinux` derivation, pulls the pre-sauced CachyOS source tarball
- `config.nix` — kernel config as `structuredExtraConfig` (bore, O3, BBR, full tick/preempt, amdgpu off)

## Versions and hashes

`kernel.nix` pins two fetches, both with real hashes already filled:
- the CachyOS source tarball `cachyos-7.2.10-1.tar.gz`;
- the base config `linux-cachyos-bore/config` at `configCommit`, dropped into
  `arch/x86/configs/niko_defconfig` — `structuredExtraConfig` (`config.nix`) layers on top.

When bumping `version` / `configCommit`, set the matching `hash` back to
`lib.fakeHash`, run `nix build .#niko-kernel`, and paste the real hash from the
`got: sha256-...` error (or `nix store prefetch-file <url>`).

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
