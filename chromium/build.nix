{ pkgs ? import <nixpkgs> {}, v}: pkgs.callPackage ./default.nix { version = v;}
