{
  lib,
  buildLinux,
  fetchurl,
  applyPatches,
  stdenvLLVM,
  ltoMakeflags,
  # everything config.nix takes: amdgpu, nouveau, polly, bore, cachy, native, hz, preempt, ...
  kconfig ? { },
  # passed explicitly: callPackage would fill it with pkgs.kernelPatches
  kernelPatches,
  structuredExtraConfig ? import ./config.nix ({ inherit lib; } // kconfig),
  features ? { },
  randstructSeed ? "",
  argsOverride ? { },
}:

let
  version = "7.3.1";
  cachyRel = "cachyos-7.3.1-1";
  configCommit = "cbd3c2573e7281c006e8f4dbf4e2dd781542d7f7";

  # `make config` asks e.g. DRM_TTM before the drivers that select it, so an `n`
  # answer is rejected while the defconfig still has them =m. Unset every `n` upfront.
  noOptions = lib.attrNames (
    lib.filterAttrs (_: v: (v.content.tristate or null) == "n") structuredExtraConfig
  );

  cachyConfig = fetchurl {
    url = "https://raw.githubusercontent.com/CachyOS/linux-cachyos/${configCommit}/linux-cachyos-bore/config";
    hash = "sha256-gftW/jJmEqDcRwX8XsMJ0EvP/7SH2wy1hDkY/pKVGSc=";
  };
in
buildLinux (
  {
    inherit version;
    pname = "niko-kernel";
    modDirVersion = "${version}-niko";

    src = applyPatches {
      name = "niko-kernel-${version}-src";
      src = fetchurl {
        url = "https://github.com/CachyOS/linux/releases/download/${cachyRel}/${cachyRel}.tar.gz";
        hash = "sha256-Pbopqo59zaQ67miY5MZt+/2ZfrXZAlELD66sxpbd+z8=";
      };
      postPatch = ''
        cp ${cachyConfig} arch/x86/configs/niko_defconfig
        sed -i -E 's/^CONFIG_(${lib.concatStringsSep "|" noOptions})=.*/# CONFIG_\1 is not set/' arch/x86/configs/niko_defconfig
      '';
    };

    stdenv = stdenvLLVM;
    extraMakeFlags = ltoMakeflags;

    defconfig = "niko_defconfig";

    ignoreConfigErrors = true;

    inherit
      kernelPatches
      structuredExtraConfig
      features
      randstructSeed
      ;

    extraMeta = {
      branch = lib.versions.majorMinor version;
      description = "niko-kernel ${version} (clang+thinLTO)";
    };
  }
  // argsOverride
)
