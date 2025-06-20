{
  description = "A Nix-flake-based Java development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs =
    { self, nixpkgs }:
    let
      javaVersion = 21; # Change this value to update the whole stack

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: rec {
        jdk = prev."jdk${toString javaVersion}";
        maven = prev.maven.override { jdk_headless = jdk; };
        gradle = prev.gradle.override { java = jdk; };
      };

      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          myAliases = [
            (pkgs.writeShellScriptBin "g" "git $@")
            (pkgs.writeShellScriptBin "c" "codium --profile 'Java' $@")
          ];
        in
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                gcc
                gradle
                jdk
                maven
                ncurses
                patchelf
                zlib
              ]
              ++ myAliases;

            shellHook = ''
              export JAVA_HOME=${pkgs.jdk}
              PATH="${pkgs.jdk}/bin:$PATH"
            '';
            buildInputs = [ pkgs.bashInteractive ];
          };
        }
      );
    };
}
