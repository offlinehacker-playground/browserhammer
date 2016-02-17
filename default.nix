{ pkgs ? import <nixpkgs> {}}:

with pkgs.lib;

let
  firefox = pkgs.callPackage ./firefox { };
  opera = pkgs.callPackage ./opera { };
  chromium = pkgs.callPackage ./chromium { };

  foxes = import ./firefox/foxes.nix;
  chromiums = import ./chromium/chromiums.nix;
  operas = import ./opera/operas.nix;
in pkgs.buildEnv {
  name = "browserhammer";
  paths =
   (mapAttrsToList (version: _:  (firefox.override { inherit version; })) foxes) ++
   (mapAttrsToList (version: _:  (chromium.override { inherit version; })) chromiums) ++
   (mapAttrsToList (version: _:  (opera.override { inherit version; })) operas);
  ignoreCollisions = true;
}
