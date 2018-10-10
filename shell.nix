{ nixpkgs ? import <nixpkgs> {}, compiler ? "default", doBenchmark ? false }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, async, base, binary, bytestring, posix-pty
      , process, stdenv, websockets, wai-websockets
      }:
      mkDerivation {
        pname = "wsterm";
        version = "0.1.0.0";
        src = ./.;
        isLibrary = false;
        isExecutable = true;
        executableHaskellDepends = [
          async base binary bytestring posix-pty process websockets wai-websockets
        ];
        license = stdenv.lib.licenses.bsd3;
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  variant = if doBenchmark then pkgs.haskell.lib.doBenchmark else pkgs.lib.id;

  drv = variant (haskellPackages.callPackage f {
    posix-pty = pkgs.haskell.lib.dontCheck haskellPackages.posix-pty;
  });

in

  if pkgs.lib.inNixShell then drv.env else drv
