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

      llvmPackages = pkgs.llvmPackages_latest;

      mkKernel =
        { amdgpu ? true, argsOverride ? { } }:
        pkgs.callPackage ./kernel.nix { inherit amdgpu argsOverride llvmPackages; };

      niko-kernel = mkKernel { amdgpu = true; };
      niko-kernel-noamdgpu = mkKernel { amdgpu = false; };
    in
    {
      packages.${system} = {
        default = niko-kernel;
        inherit niko-kernel niko-kernel-noamdgpu;
      };

      legacyPackages.${system} = {
        linuxPackages-niko = pkgs.linuxPackagesFor niko-kernel;
        linuxPackages-niko-noamdgpu = pkgs.linuxPackagesFor niko-kernel-noamdgpu;
      };

      nixosModules.default =
        { pkgs, ... }:
        {
          boot.kernelPackages = pkgs.linuxPackagesFor (
            pkgs.callPackage ./kernel.nix {
              amdgpu = true;
              llvmPackages = pkgs.llvmPackages_latest;
            }
          );
        };

      overlays.default = final: _prev: {
        niko-kernel = final.callPackage ./kernel.nix {
          amdgpu = true;
          llvmPackages = final.llvmPackages_latest;
        };
        linuxPackages-niko = final.linuxPackagesFor final.niko-kernel;
      };
    };
}
