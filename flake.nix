{
  description = "Set of simple, performant neovim plugins";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          self,
          config,
          self',
          inputs',
          pkgs,
          system,
          lib,
          ...
        }:
        {
          # use fenix overlay
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [ inputs.fenix.overlays.default ];
          };

          # define the packages provided by this flake
          packages =
            let
              src = ./.;
              version = "0.8.2";
            in
            {
              blink-fuzzy-lib =
                let
                  inherit (inputs.fenix.packages.${system}.minimal) toolchain;
                  rustPlatform = pkgs.makeRustPlatform {
                    cargo = toolchain;
                    rustc = toolchain;
                  };
                in
                rustPlatform.buildRustPackage {
                  pname = "blink-fuzzy-lib";
                  inherit src version;
                  useFetchCargoVendor = true;
                  cargoHash = "sha256-t84hokb2loZ6FPPt4eN8HzgNQJrQUdiG5//ZbmlasWY=";

                  nativeBuildInputs = with pkgs; [ git ];
                };

              blink-cmp = pkgs.vimUtils.buildVimPlugin {
                pname = "blink-cmp";
                inherit src version;
                preInstall = ''
                  mkdir -p target/release
                  ln -s ${self'.packages.blink-fuzzy-lib}/lib/libblink_cmp_fuzzy.* target/release/
                '';
              };

              default = self'.packages.blink-cmp;
            };

          # builds the native module of the plugin
          apps.build-plugin = {
            type = "app";
            program =
              let
                buildScript = pkgs.writeShellApplication {
                  name = "build-plugin";
                  runtimeInputs = with pkgs; [
                    fenix.minimal.toolchain
                    gcc
                  ];
                  text = ''
                    cargo build --release
                  '';
                };
              in
              (lib.getExe buildScript);
          };

          # define the default dev environment
          devShells.default = pkgs.mkShell {
            name = "blink";
            inputsFrom = [
              self'.packages.blink-fuzzy-lib
              self'.packages.blink-cmp
              self'.apps.build-plugin
            ];
            packages = with pkgs; [
              rust-analyzer-nightly
            ];
          };

          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
