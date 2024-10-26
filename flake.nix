{
  description = "Set of simple, performant neovim plugins";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { self, config, self', inputs', pkgs, system, lib, ... }: {
        # use fenix overlay
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [ inputs.fenix.overlays.default ];
        };

        # define the packages provided by this flake
        packages = let
          inherit (inputs.fenix.packages.${system}.minimal) toolchain;
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
                "frizbee-0.1.0" =
                  "sha256-eYth+xOIqwGPkH39OxNCMA9zE+5CTNpsuX8Ue/mySIA=";
              };
            };
          };

          libExt = if hostPlatform.isDarwin then
            "dylib"
          else if hostPlatform.isWindows then
            "dll"
          else
            "so";
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

        # builds the native module of the plugin
        apps.build-plugin = {
          type = "app";
          program = let
            buildScript = pkgs.writeShellApplication {
              name = "build-plugin";
              runtimeInputs = with pkgs; [
                fenix.complete.toolchain
                rust-analyzer-nightly
              ];
              text = ''
                cargo build --release
              '';
            };
          in (lib.getExe buildScript);
        };

        # define the default dev environment
        devShells.default = pkgs.mkShell {
          name = "blink";
          packages = with pkgs; [ fenix.minimal.toolchain ];
        };
      };
    };
}
