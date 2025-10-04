{
  description = "Development Shell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            echo "Development environment loaded"
          '';
          packages = with pkgs; [
            gleam
            erlang_27
            nodejs_22
            rebar3
            inotify-tools
          ];
        };
      }
    );
}
