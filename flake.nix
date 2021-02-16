{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        gdk = pkgs.buildRubyGem {
          ruby = pkgs.ruby_2_7;
          gemName = "gitlab-development-kit";
          version = "0.2.8";
          source = {
            sha256 = "1c0ir4ncns2my6ggbp6nwnapf7hlckiwfx8kfn3yygkc6bb2rrrz";
          };
        };
        gems = pkgs.bundlerEnv {
          name = "gems-for-gdk";
          gemdir = ./.;
          ruby = pkgs.ruby_2_7;
          gemConfig = pkgs.defaultGemConfig // {
            openssl = attrs: {
              buildFlags = [ "--with-openssl-dir=${pkgs.openssl.dev}" ];
              buildInputs = [ pkgs.openssl.dev ];
            };
          };
        };
        gitlab = if builtins.pathExists ./gitlab then
          import ./gitlab { pkgs = pkgs; }
        else
          [ ];

      in {
        devShell = pkgs.mkShell {

          buildInputs = with pkgs;
            [
              binutils
              icu
              cmake
              gcc
              re2
              krb5
              sqlite
              readline
              zlib
              pkg-config
              graphicsmagick
              exiftool
              openssl
              pcre2
              git
              git-lfs
              rsync
              runit
              curl
              tzdata
              gems

              (ruby_2_7.withPackages (ps: with ps; [ bundler ]))
              gdk
              postgresql
              yarn
              nodejs-14_x
              go
              redis
            ] ++ gitlab;
        };
      });
}
