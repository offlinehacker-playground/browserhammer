#!/usr/bin/env bash
echo "{" > foxes.nix
for x in $@; do
    echo "fetching hash for fox $x"
    echo -n "\"$x\"= \"" >> foxes.nix
    hash=$(curl https://ftp.mozilla.org/pub/mozilla.org/firefox/releases/$x/MD5SUMS | grep x86_64 | grep en-US | grep "firefox-$x.tar.bz2" | grep -v asc | cut -d " " -f 1 | tr -d '\n')
    echo "hash is $hash"
    echo -n $hash >> foxes.nix
    echo "\";" >> foxes.nix
done
echo "}" >> foxes.nix
