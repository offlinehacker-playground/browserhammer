{
  version ? 2
, stdenv
, fetchurl
, makeWrapper
, unzip
, glib
, nss
, nspr
, gnome
, fontconfig
, freetype
, pango
, cairo
, xlibs
, alsaLib
, expat
, cups
, libcap
, node_webkit
, gtk2
, gdk_pixbuf
, dbus
, xscreensaver
, gcc
}:

with stdenv.lib;

let 
  versions = import ./chromiums.nix;
in stdenv.mkDerivation rec {
  name = "chromium-bin-${version}";

  src = fetchurl {
    url = versions."${version}".url;
    sha256 = versions."${version}".sha256;
  };

  buildInputs = [ unzip makeWrapper ];

  libPath = (stdenv.lib.makeLibraryPath [
    glib nss nspr gnome.GConf fontconfig freetype pango cairo
    xlibs.libX11 xlibs.libXi xlibs.libXcursor xlibs.libXext xlibs.libXfixes
    xlibs.libXrender xlibs.libXcomposite xlibs.libXdamage xlibs.libXtst
    xlibs.libXrandr xlibs.libXScrnSaver
    expat cups alsaLib libcap gtk2 gdk_pixbuf dbus gcc.gcc
  ]) + ":${node_webkit}/share/node-webkit/"; 

  dontStrip = 1;

  installPhase = ''
    mkdir -p "$out/usr/lib/chromium-bin-${version}"
    cp -r * "$out/usr/lib/chromium-bin-${version}"

    mkdir -p "$out/bin"
    makeWrapper \
      "$out/usr/lib/chromium-bin-${version}/chrome" \
      "$out/bin/chromium-${version}" \
      --add-flags "--disable-setuid-sandbox"

    patchelf \
      --set-interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      "$out/usr/lib/chromium-bin-${version}/chrome"

    patchelf \
      --set-interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
      --set-rpath "${libPath}" \
      "$out/usr/lib/chromium-bin-${version}/nacl_helper"
  '';
}
