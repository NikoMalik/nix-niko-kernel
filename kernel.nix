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
  version = "7.2.10";
  cachyRel = "cachyos-${version}-1";
  configCommit = "5a14cc870dbe958da0fe3fff96d0df6561b8b064";

  cachyConfig = fetchurl {
    url = "https://raw.githubusercontent.com/CachyOS/linux-cachyos/${configCommit}/linux-cachyos-bore/config";
    hash = "sha256-PfMxEuM1f+tqiZu/wAby3tFSJtGy63QayYbVgbnKd3M=";
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
        hash = "sha256-Aq+KYRVZbSDpmYkmlT8gQPjX9myhEi85nFkgqWAfHO8=";
      };
      postPatch = ''
        cp ${cachyConfig} arch/x86/configs/niko_defconfig
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
