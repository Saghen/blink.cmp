{
  description = "Set of simple, performant neovim plugins";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-trusted-public-keys =
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, nixpkgs, fenix, ... }:
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
        packages = let
          inherit (fenix.packages.${system}.minimal) toolchain;
          inherit (pkgs.stdenv) hostPlatform;

          rustPlatform = pkgs.makeRustPlatform {
            cargo = toolchain;
            rustc = toolchain;
          };

          src = ./.;
          version = "2024-08-02";

          blink-fuzzy-lib = rustPlatform.buildRustPackage {
            pname = "blink-fuzzy-lib";
            inherit src version;
            cargoLock = {
              lockFile = ./Cargo.lock;
              outputHashes = {
                "c-marshalling-0.2.0" =
                  "sha256-eL6nkZOtuLLQ0r31X7uroUUDYZsWOJ9KNXl4NCVNRuw=";
                "frizbee-0.1.0" =
                  "sha256-zO2S282DVCjnALMXu3GxmAfjCXsPNUZ7+xgiqITfGmU=";
              };
            };
          };
          
          libExt = 
            if hostPlatform.isDarwin then "dylib"
            else if hostPlatform.isWindows then "dll"
            else "so";       
        in {
          blink-cmp = pkgs.vimUtils.buildVimPlugin {
            pname = "blink-cmp";
            inherit src version;
            preInstall = ''
              mkdir -p target/release
              ln -s ${blink-fuzzy-lib}/lib/libblink_cmp_fuzzy.${libExt} target/release/libblink_cmp_fuzzy.${libExt}
            '';

            meta = {
              description =
                "Performant, batteries-included completion plugin for Neovim ";
              homepage = "https://github.com/saghen/blink.cmp";
              license = lib.licenses.mit;
              maintainers = with lib.maintainers; [ redxtech ];
            };
          };

          default = self'.packages.blink-cmp;
        };

        # define the default dev environment
        devenv.shells.default = {
          name = "blink";

          languages.rust = {
            enable = true;
            channel = "nightly";
          };
        };
      };
    };
}
