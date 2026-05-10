{
  description = "T3 Code development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        t3code-rebuild-native-deps = pkgs.writeShellApplication {
          name = "t3code-rebuild-native-deps";
          runtimeInputs = [ pkgs.node-gyp ];
          text = ''
            node_pty_dir="$PWD/node_modules/.bun/node-pty@1.1.0/node_modules/node-pty"
            if [ -f "$node_pty_dir/binding.gyp" ] && [ ! -f "$node_pty_dir/build/Release/pty.node" ]; then
              echo "Building node-pty native module..."
              (cd "$node_pty_dir" && node-gyp rebuild)
            fi
          '';
        };

        t3code-bootstrap = pkgs.writeShellApplication {
          name = "t3code-bootstrap";
          runtimeInputs = [
            pkgs.bun
            t3code-rebuild-native-deps
          ];
          text = ''
            bun install
            t3code-rebuild-native-deps
          '';
        };

        runtimeLibs = with pkgs; [
          alsa-lib
          at-spi2-atk
          at-spi2-core
          cairo
          cups
          dbus
          expat
          fontconfig
          freetype
          glib
          gtk3
          libdrm
          libGL
          libxkbcommon
          mesa
          nspr
          nss
          pango
          stdenv.cc.cc
          udev
          libx11
          libxcb
          libxcomposite
          libxcursor
          libxdamage
          libxext
          libxfixes
          libxi
          libxrandr
          libxrender
          libxscrnsaver
          libxtst
          libxshmfence
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bun
            curl
            gcc
            git
            gnumake
            node-gyp
            nodejs_24
            pkg-config
            python3
            ripgrep
            sqlite
            t3code-bootstrap
            t3code-rebuild-native-deps
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
          npm_config_nodedir = "${pkgs.nodejs_24}";
          PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"
            t3code-rebuild-native-deps
            echo "T3 Code dev shell: node $(node --version), bun $(bun --version)"
            echo "Run: t3code-bootstrap && bun dev"
          '';
        };
      }
    );
}
