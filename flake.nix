{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
      ];
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.marp-cli
          ];
          shellHook = ''
            echo "$motd" >&2
          '';
          motd = ''
            Hello! The following commands are available:

                - live

          '';
        };
        packages.default = pkgs.stdenv.mkDerivation {
          name = "nixops4-quick-intro";
          nativeBuildInputs = [
            pkgs.marp-cli
          ];
          src = ./.;
      	  buildPhase = ''
            ls -al
            marp slides.md
          '';
          installPhase = ''
            mkdir $out
            cp slides.html $out/
            cp *.png *.svg $out/
          '';
        };
        apps.default.program = pkgs.writeScriptBin "open-slides" ''
          #!${pkgs.runtimeShell}
          ${if pkgs.stdenv.hostPlatform.isDarwin then "open" else "xdg-open"} ${config.packages.default}/slides.html
        '';
      };
    };
}
