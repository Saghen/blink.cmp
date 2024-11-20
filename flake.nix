{
  description = "Set of simple, performant neovim plugins";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', pkgs, system, lib, ... }: {
        # use fenix overlay
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [ 
            inputs.fenix.overlays.default 
            self.overlays.default
          ];
        };

        # define the packages provided by this flake
        packages = {
          blink-cmp = pkgs.vimPlugins.blink-cmp;
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
          packages = with pkgs; [ 
            fenix.minimal.toolchain 
            rust-analyzer
            rustfmt
            clippy
            lua-language-server
            luarocks
            (lua5_1.withPackages (ps: with ps; [nlua busted]))
          ];
        };
      };
      flake = {
        overlays.default = final: prev: let
          lib = final.lib;
          inherit (inputs.fenix.packages.${final.system}.minimal) toolchain cargo rustc;

          rustPlatform = final.makeRustPlatform {
            cargo = toolchain;
            rustc = toolchain;
          };
          luaPackage-override = luafinal: luaprev: {
            blink-cmp = luafinal.callPackage ({
              buildLuarocksPackage,
              fetchzip,
              fetchurl,
              lua,
              luaOlder,
              luarocks-build-rust-mlua,
              busted,
              nlua,
            }:
              buildLuarocksPackage {
                pname = "blink.cmp";
                version = "scm-1";
                knownRockspec = "${self}/blink.cmp-scm-1.rockspec";
                src = self;
                disabled = luaOlder "5.1";
                cargoDeps = final.rustPlatform.importCargoLock {
                  lockFile = self + "/Cargo.lock";
                  outputHashes = {
                    "frizbee-0.1.0" = "sha256-pt6sMsRyjXrbrTK7t/YvWeen/n3nU8UUaiNYTY1LczE=";
                  };
                };
                NIX_LDFLAGS = lib.optionalString final.stdenv.hostPlatform.isDarwin
                  (if lua.pkgs.isLuaJIT then "-lluajit-${lua.luaversion}" else "-llua");
                buildInputs = [
                  cargo
                  rustc
                  rustPlatform.cargoSetupHook
                  luarocks-build-rust-mlua
                ];
                propagatedBuildInputs = [
                  # HACK: These packages shouldn't be propagated, but without this,
                  # luarocks make fails in the preCheck (needs to be fixed in nixpkgs).
                  luarocks-build-rust-mlua
                  busted
                  nlua
                ];
                doCheck = true;
                preCheck = ''
                  export HOME="$(mktemp -d)"
                  mkdir -p .luarocks
                  luarocks $LUAROCKS_EXTRA_ARGS make --tree=.luarocks --deps-mode=all
                '';
                meta = {
                  description =
                    "Performant, batteries-included completion plugin for Neovim ";
                  homepage = "https://github.com/saghen/blink.cmp";
                  license = lib.licenses.mit;
                  maintainers = with lib.maintainers; [ redxtech ];
                };
            }) {};
          };
        in {
          lua5_1 = prev.lua5_1.override {
            packageOverrides = luaPackage-override;
          };
          lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;
          vimPlugins = prev.vimPlugins // {
            blink-cmp = final.neovimUtils.buildNeovimPlugin {
              luaAttr = final.lua51Packages.blink-cmp;
            };
          };
        };
      };
    };
}
