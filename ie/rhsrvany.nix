{ pkgs ? import <nixpkgs> { 
    crossSystem = {
      # That's the triplet they use in the mingw-w64 docs,
      # and it's relevant for nixpkgs conditions.
      config = "i686-w64-mingw32";
      arch = "x86"; # Irrelevant
      libc = "msvcrt"; # This distinguishes the mingw (non posix) toolchain
      platform = {};
      openssl.system = "mingw64";
    };
  }
}:

pkgs.stdenv.mkDerivation rec {
  name = "rhsrvany-${version}";
  version = "ffbc72df6c";

  nativeBuildInputs = with pkgs; [automake autoconf];

  src = pkgs.fetchgit {
    url = "https://github.com/rwmjones/rhsrvany.git";
    rev = "ffbc72df6ce09c9811bdce57205c996d71112e71";
    sha256 = "659c0ee90f5fa95b372a02ebb5f0aa536b23cab003973f5558c01c72618e873a";
  };

  preConfigure = ''
    autoreconf -i --verbose
  '';
}
