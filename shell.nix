{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
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
}
