{
  description = "A Nix-flake-based Node.js development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  inputs.utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        myAliases = [
          (pkgs.writeShellScriptBin "g" "git $@")
          (pkgs.writeShellScriptBin "c" "codium --profile 'Web' $@")
        ];
      in
      {
        overlays.default = final: prev: rec {
          nodejs = prev.nodejs;
          yarn = (prev.yarn.override { inherit nodejs; });
        };

        # Used by `nix develop`
        devShells.default = pkgs.mkShell rec {
          packages =
            with pkgs;
            [
              bashInteractive
              node2nix
              nodejs
              nodePackages.pnpm
              yarn
              cypress
            ]
            ++ myAliases;

          buildInputs = with pkgs; [
            chromium
            glib
            dbus
          ];

          shellHook = ''
            export CYPRESS_INSTALL_BINARY=0
            export CYPRESS_RUN_BINARY=${pkgs.cypress}/bin/Cypress
          '';
        };
      }
    );

}
