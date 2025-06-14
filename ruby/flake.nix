{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-ruby.url = "github:bobvanderlinden/nixpkgs-ruby";
    nixpkgs-ruby.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-ruby,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = nixpkgs-ruby.lib.packageFromRubyVersionFile {
          file = ./.ruby-version;
          inherit system;
        };

        gems = pkgs.bundlerEnv {
          name = "gemset";
          inherit ruby;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = ./gemset.nix;
          groups = [
            "default"
            "production"
            "development"
            "test"
          ];
        };
        myAliases = [
          (pkgs.writeShellScriptBin "g" "git $@")
          (pkgs.writeShellScriptBin "c" "codium --profile 'Ruby' $@")
        ];
      in
      {
        devShell =
          with pkgs;
          mkShell {
            buildInputs = [
              # gems
              ruby
              bundix
              bashInteractive
            ];

            packages = with pkgs; [
              zlib
              libyaml
              pkg-config
              libffi
              openssl
              postgresql
            ] ++ myAliases;

            shellHook = ''
              export SHELL=/run/current-system/sw/bin/bash
              export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
              export PATH="$PATH:$GEM_HOME/bin"
              export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
              export BUNDLE_PATH="$GEM_HOME"
            '';
          };
      }
    );
}
