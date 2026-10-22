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

## Toolchain

clang + ThinLTO only (no GCC — the patches are clang-only). `kernel.nix` sets
`stdenv = llvmPackages.stdenv` + `extraMakeFlags = [ "LLVM=1" ]`, config has
`LTO_CLANG_THIN=y`. `llvmPackages_latest` is used; pin a specific
`llvmPackages_NN` in `flake.nix` if a newer clang breaks the build. If clang is
not picked up, override explicitly: `(niko-kernel).override { stdenv = llvmPackages.stdenv; }`.


## Notes

- NVIDIA is out-of-tree (`hardware.nvidia`), independent of this kernel; nouveau is off. // and use rss-stat patch for nvidia(from niko-patches)
