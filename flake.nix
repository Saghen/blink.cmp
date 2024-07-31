{
  description = "Super amazing neovim completion plugin";

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
          toolchain = fenix.packages.${system}.minimal.toolchain;
          rustPlatform = pkgs.makeRustPlatform {
            cargo = toolchain;
            rustc = toolchain;
          };
          fuzzy = rustPlatform.buildRustPackage {
            pname = "blink-cmp-lib";
            version = "2024-07-26";

            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
              outputHashes = {
                "c-marshalling-0.2.0" =
                  "sha256-eL6nkZOtuLLQ0r31X7uroUUDYZsWOJ9KNXl4NCVNRuw=";
                "frizbee-0.1.0" =
                  "sha256-+Os6ioFXB2K86V/8Z2xNxmO7jo3RLC9VKpuztQRrIgE=";
              };
            };
          };
        in {
          blink-cmp = pkgs.vimUtils.buildVimPlugin {
            pname = "blink-cmp";
            version = "2024-07-26";

            src = ./.;

						preInstall = ''
							mkdir -p target/release
							ln -s ${fuzzy}/lib/libblink_cmp_fuzzy.so target/release/libblink_cmp_fuzzy.so
						'';

            meta = {
              description = "Super amazing neovim completion plugin";
              homepage = "https://github.com/saghen/blink.cmp";
              license = lib.licenses.mit;
              maintainers = with lib.maintainers; [ redxtech ];
            };
          };

          default = self'.packages.blink-cmp;
        };

        # define the default dev environment
        devenv.shells.default = {
          name = "fuzzy";

          languages.rust = {
            enable = true;
            channel = "nightly";
          };
        };
      };
    };
}
