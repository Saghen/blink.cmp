{
  description = "Fuzzy search with rust.";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
    naersk.url = "github:nix-community/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, nixpkgs, fenix, naersk, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = { config, self', inputs', pkgs, system, lib, ... }: {
        # define the packages provided by this flake
        packages = {
          fuzzy = let
            # use the minimal nightly toolchain provided by fenix
            toolchain = inputs'.fenix.packages.minimal.toolchain;
            nearskLib = inputs.naersk.lib.${system}.override {
              cargo = toolchain;
              rustc = toolchain;
            };
          in nearskLib.buildPackage { src = ./lua/blink/fuzzy; };

          default = self'.packages.fuzzy;
        };

        # define the default dev environment
        devenv.shells.default = {
          name = "fuzzy";

          languages.rust = {
            enable = true;
            channel = "nightly";
          };

          packages = [ config.packages.default pkgs.gnumake ];

          scripts.build.exec = "make";
        };
      };
    };
}
