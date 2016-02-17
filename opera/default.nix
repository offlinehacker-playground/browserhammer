{ version ? "12.16"
, stdenv, fetchurl, zlib, libX11, libXext, libSM, libICE, libXt
, freetype, fontconfig, libXft, libXrender, libxcb, expat, libXau, libXdmcp
, libuuid, cups, xz
, gstreamer, gst_plugins_base, libxml2
, gtkSupport ? true, glib, gtk, pango, gdk_pixbuf, cairo, atk
}:

assert stdenv.isLinux && stdenv.gcc.gcc != null && stdenv.gcc.libc != null;

let
  versions = import ./operas.nix;
in stdenv.mkDerivation rec {
  name = "opera-${version}";

  src = fetchurl {
    url = versions."${version}".url;
    sha256 = versions."${version}".sha256;
  };

  dontStrip = 1;

  phases = "unpackPhase installPhase fixupPhase";

  installPhase = ''
    ./install --unattended --prefix $out
    '';

  buildInputs =
    [ stdenv.gcc.gcc stdenv.gcc.libc zlib libX11 libXt libXext libSM libICE
      libXft freetype fontconfig libXrender libuuid expat
      gstreamer libxml2 gst_plugins_base
    ]
    ++ stdenv.lib.optionals gtkSupport [ glib gtk pango gdk_pixbuf cairo atk ];

  libPath = stdenv.lib.makeLibraryPath buildInputs
    + stdenv.lib.optionalString (stdenv.system == "x86_64-linux")
      (":" + stdenv.lib.makeSearchPath "lib64" buildInputs);

  preFixup =
    ''
    find $out/lib/opera -type f | while read f; do
      type=$(readelf -h "$f" 2>/dev/null | grep 'Type:' | sed -e 's/ *Type: *\([A-Z]*\) (.*/\1/')
      if [ -z "$type" ]; then
        :
      elif [ $type == "EXEC" ]; then
        echo "patching $f executable <<"
        patchelf \
            --set-interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" \
            --set-rpath "${libPath}" \
            "$f"
      elif [ $type == "DYN" ]; then
        echo "patching $f library <<"
        patchelf --set-rpath "${libPath}" "$f"
      else
        echo "Unknown type $type"
        exit 1
      fi
    done
    '';

  postFixup = ''
    oldRPATH=`patchelf --print-rpath $out/lib/opera/opera`
    patchelf --set-rpath $oldRPATH:${cups}/lib $out/lib/opera/opera

    # This file should normally require a gtk-update-icon-cache -q /usr/share/icons/hicolor command
    # It have no reasons to exist in a redistribuable package
    rm $out/share/icons/hicolor/icon-theme.cache

    mv $out/bin/opera $out/bin/opera-${version}
    rm $out/bin/uninstall-opera
  '';
}
