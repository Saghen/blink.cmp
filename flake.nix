{
  description = "Fuzzy search with rust.";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";
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
        packages = {
          fuzzy = let toolchain = inputs'.fenix.packages.minimal.toolchain;
          in (pkgs.makeRustPlatform {
            cargo = toolchain;
            rustc = toolchain;
          }).buildRustPackage {
            pname = "fuzzy";
            version = "0.1.0";

            src = ./lua/blink/fuzzy;

            cargoLock = {
              lockFile = ./lua/blink/fuzzy/Cargo.lock;
              outputHashes = {
                "c-marshalling-0.2.0" =
                  "sha256-eL6nkZOtuLLQ0r31X7uroUUDYZsWOJ9KNXl4NCVNRuw=";
              };
            };
          };

          default = self'.packages.fuzzy;
        };

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
      flake = { };
    };
}
