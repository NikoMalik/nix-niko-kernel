{
  description = "niko-kernel: CachyOS 7.2 bore base for NixOS, clang+thinLTO, amdgpu optional";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = pkgs.lib;

      llvm = import ./llvm.nix { inherit pkgs lib; };

      # any config.nix parameter: amdgpu nouveau polly bore cachy native x86Level hz preempt preemptDynamic nohzFull extraConfig
      profiles = {
        desktop = { };
        server = {
          bore = false;
          cachy = false;
          hz = 300;
          preempt = "none";
          nohzFull = false;
          amdgpu = false;
          nouveau = false;
        };
      };

      mkKernel =
        { argsOverride ? { }, ... }@kconfig:
        pkgs.callPackage ./kernel.nix {
          inherit argsOverride;
          kconfig = removeAttrs kconfig [ "argsOverride" ];
          inherit (llvm) ltoMakeflags;
          stdenvLLVM =
            if kconfig.native or true then pkgs.impureUseNativeOptimizations llvm.stdenvLLVM else llvm.stdenvLLVM;
          kernelPatches = import ./patches.nix { preemptNone = (kconfig.preempt or "full") == "none"; };
        };

      mkPackages = kernel: llvm.kernelModuleLLVMOverride (pkgs.linuxPackagesFor kernel);

      # unstable buildLinux puts modules in a separate `modules` output; stable NixOS
      # (25.05) still looks in `kernel/lib/modules`, so point it there explicitly
      mkModule =
        kernel:
        { config, lib, ... }:
        {
          boot.kernelPackages = mkPackages kernel;
          system.modulesTree = lib.mkForce (
            [ (lib.getOutput "modules" config.boot.kernelPackages.kernel) ] ++ config.boot.extraModulePackages
          );
        };

      niko-kernel = mkKernel profiles.desktop;
      niko-kernel-noamdgpu = mkKernel { amdgpu = false; };
      niko-kernel-server = mkKernel profiles.server;
    in
    {
      packages.${system} = {
        default = niko-kernel;
        inherit niko-kernel niko-kernel-noamdgpu niko-kernel-server;
      };

      # custom builds: niko-kernel.lib.mkKernel (niko-kernel.lib.profiles.server // { hz = 250; })
      lib = { inherit profiles mkKernel mkPackages; };

      legacyPackages.${system} = {
        linuxPackages-niko = mkPackages niko-kernel;
        linuxPackages-niko-noamdgpu = mkPackages niko-kernel-noamdgpu;
        linuxPackages-niko-server = mkPackages niko-kernel-server;
      };

      checks.${system} = {
        boot = import ./tests.nix {
          inherit pkgs;
          linuxPackages = mkPackages niko-kernel;
        };
        boot-server = import ./tests.nix {
          inherit pkgs;
          linuxPackages = mkPackages niko-kernel-server;
        };
      };

      nixosModules.default = mkModule niko-kernel;
      nixosModules.server = mkModule niko-kernel-server;

      overlays.default = _final: _prev: {
        niko-kernel = niko-kernel;
        linuxPackages-niko = mkPackages niko-kernel;
        niko-kernel-server = niko-kernel-server;
        linuxPackages-niko-server = mkPackages niko-kernel-server;
      };
    };
}
