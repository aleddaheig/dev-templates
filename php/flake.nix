{
  description = "A Nix-flake-based PHP development environment";

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
        php = pkgs.php84.buildEnv {
          extensions = (
            { enabled, all }:
            enabled
            ++ (with all; [
              pcov
            ])
          );
          extraConfig = ''
            pcov.enabled = 1
          '';
        };
        myAliases = [
          (pkgs.writeShellScriptBin "g" "git $@")
          (pkgs.writeShellScriptBin "c" "codium --profile 'Laravel' $@")
        ];
      in
      {
        devShells.default = pkgs.mkShell rec
        {
          packages =
            with pkgs;
            [
              php
              (php84Packages.composer.override {
                php = php;
              })
              php84Packages.phpinsights
              php84Packages.phpmd
              yarn
              nodejs_20
              fontconfig
              chromium
              python311
              stripe-cli
            ]
            ++ (with python311Packages; [
              pip
            ])
            ++ myAliases;

          buildInputs = with pkgs; [
            bashInteractive
          ];

          shellHooks = ''
            alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'
            export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
            export PUPPETEER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
          '';
        };
      }
    );
}
