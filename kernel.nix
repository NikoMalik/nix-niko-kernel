{
  lib,
  buildLinux,
  fetchurl,
  stdenvLLVM,
  ltoMakeflags,
  amdgpu ? true,
  polly ? false,
  kernelPatches ? import ./patches.nix,
  structuredExtraConfig ? import ./config.nix { inherit lib amdgpu polly; },
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
    hash = lib.fakeHash;
  };
in
buildLinux (
  {
    inherit version;
    pname = "niko-kernel";
    modDirVersion = "${version}-niko";

    src = fetchurl {
      url = "https://github.com/CachyOS/linux/releases/download/${cachyRel}/${cachyRel}.tar.gz";
      hash = lib.fakeHash;
    };

    stdenv = stdenvLLVM;
    extraMakeFlags = ltoMakeflags;

    postPatch = ''
      cp ${cachyConfig} arch/x86/configs/niko_defconfig
    '';
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
      description = "niko-kernel ${version} (bore, clang+thinLTO), amdgpu ${if amdgpu then "on" else "off"}";
    };
  }
  // argsOverride
)
