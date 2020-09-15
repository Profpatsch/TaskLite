{ # Fetch the latest haskell.nix and import its default.nix
  haskellNix ? import (builtins.fetchTarball {
    url = "https://github.com/input-output-hk/haskell.nix/archive/b1c3dabc8c7ca25e74582ede28996fa119e3c5d1.tar.gz";
    sha256 = "09wjf3k97glcispw5jclnf1cq15nlzfdm3dxzq1545hbn6l8135c";
  }) {}

# haskell.nix provides access to the nixpkgs pins which are used by our CI,
# hence you will be more likely to get cache hits when using these.
# But you can also just use your own, e.g. '<nixpkgs>'.
, nixpkgsSrc ? haskellNix.sources.nixpkgs-2003

# haskell.nix provides some arguments to be passed to nixpkgs, including some
# patches and also the haskell.nix functionality itself as an overlay.
, nixpkgsArgs ? haskellNix.nixpkgsArgs

# import nixpkgs with overlays
, pkgs ? import nixpkgsSrc nixpkgsArgs
}:

let
  build = pkgs.haskell-nix.project {
    # 'cleanGit' cleans a source directory based on the files known by git
    src = pkgs.haskell-nix.haskellLib.cleanGit {
      name = "haskell-nix-project";
      src = ./.;
    };
    # For `cabal.project` based projects specify the GHC version to use.
    compiler-nix-name = "ghc884"; # Not used for `stack.yaml` based projects.
  };

  exe = build.tasklite-core.components.exes.tasklite;

  wrapped = exe.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs or [] ++ [ pkgs.makeWrapper ];
    postInstall = old.postInstall or "" + ''
      wrapProgram $out/bin/tasklite \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.python3 ]}
    '';
  });

in wrapped
