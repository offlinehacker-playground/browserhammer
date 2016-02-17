{
  version ? 33
, makeWrapper, stdenv, fetchurl, config
, alsaLib
, atk
, cairo
, cups
, dbus_glib
, dbus_libs
, fontconfig
, freetype
, gnome
, gdk_pixbuf
, glib
, glibc
, gst_plugins_base
, gstreamer
, gtk
, libcanberra
, mesa
, nspr
, nss
, pango
, heimdal
, pulseaudio
, systemd
, xlibs
}:

let 
  versions = import ./foxes.nix;
in stdenv.mkDerivation {
  name = "firefox-bin-${version}";

  src = fetchurl {
    url = "http://download-installer.cdn.mozilla.net/pub/firefox/releases/${version}/linux-x86_64/en-US/firefox-${version}.tar.bz2";
    md5 = versions."${version}";
  };

  buildInputs = [ makeWrapper ];

  phases = "unpackPhase installPhase";

  libPath = stdenv.lib.makeLibraryPath
    [ stdenv.gcc.gcc
      alsaLib
      atk
      cairo
      cups
      dbus_glib
      dbus_libs
      fontconfig
      freetype
      gnome.GConf
      gdk_pixbuf
      glib
      glibc
      gst_plugins_base
      gstreamer
      gtk
      xlibs.libX11
      xlibs.libXScrnSaver
      xlibs.libXext
      xlibs.libXinerama
      xlibs.libXrender
      xlibs.libXt
      xlibs.libXdamage
      xlibs.libXfixes
      xlibs.libXcomposite
      libcanberra
      gnome.libgnome
      gnome.libgnomeui
      mesa
      nspr
      nss
      pango
      heimdal
      pulseaudio
      systemd
    ] + ":" + stdenv.lib.makeSearchPath "lib64" [
      stdenv.gcc.gcc
    ];

  # "strip" after "patchelf" may break binaries.
  # See: https://github.com/NixOS/patchelf/issues/10
  dontStrip = 1;

  installPhase =
    ''
      mkdir -p "$prefix/usr/lib/firefox-bin-${version}"
      cp -r * "$prefix/usr/lib/firefox-bin-${version}"

      mkdir -p "$out/bin"
      makeWrapper "$prefix/usr/lib/firefox-bin-${version}/firefox" "$out/bin/firefox-${version}"

      for executable in \
        firefox mozilla-xremote-client firefox-bin plugin-container \
        updater crashreporter webapprt-stub
      do
        if [ -f "$out/usr/lib/firefox-bin-${version}/$executable" ]; then
          patchelf --interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
            "$out/usr/lib/firefox-bin-${version}/$executable" || true
        fi
      done

      for executable in \
        firefox mozilla-xremote-client firefox-bin plugin-container \
        updater crashreporter webapprt-stub libxul.so
      do
        if [ -f "$out/usr/lib/firefox-bin-${version}/$executable" ]; then
          patchelf --set-rpath "$libPath" \
            "$out/usr/lib/firefox-bin-${version}/$executable" || true
        fi
      done
    '';
}
