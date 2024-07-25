{
  description = "Fuzzy search with rust.";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
          blink-nvim = pkgs.vimUtils.buildVimPlugin {
            name = "blink-nvim";
            src = ./.;
          };

					default = self'.packages.blink-nvim;
        };
      };
    };
}
