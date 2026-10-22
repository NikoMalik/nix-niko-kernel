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

      mkKernel =
        { amdgpu ? true, polly ? false, argsOverride ? { } }:
        pkgs.callPackage ./kernel.nix {
          inherit amdgpu polly argsOverride;
          inherit (llvm) stdenvLLVM ltoMakeflags;
        };

      mkPackages = kernel: llvm.kernelModuleLLVMOverride (pkgs.linuxPackagesFor kernel);

      niko-kernel = mkKernel { amdgpu = true; };
      niko-kernel-noamdgpu = mkKernel { amdgpu = false; };
    in
    {
      packages.${system} = {
        default = niko-kernel;
        inherit niko-kernel niko-kernel-noamdgpu;
      };

      legacyPackages.${system} = {
        linuxPackages-niko = mkPackages niko-kernel;
        linuxPackages-niko-noamdgpu = mkPackages niko-kernel-noamdgpu;
      };

      checks.${system}.boot = import ./tests.nix {
        inherit pkgs;
        linuxPackages = mkPackages niko-kernel;
      };

      nixosModules.default =
        { ... }:
        {
          boot.kernelPackages = mkPackages niko-kernel;
        };

      overlays.default = _final: _prev: {
        niko-kernel = niko-kernel;
        linuxPackages-niko = mkPackages niko-kernel;
      };
    };
}
