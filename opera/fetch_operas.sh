#!/usr/bin/env bash
echo "{" > operas.nix
while read line; do
    url=$(echo $line | cut -d " " -f 1)
    version=$(echo $line | cut -d " " -f 2)
    echo "fetching hash for fox $version"
    echo -n "\"$version\" = { " >> operas.nix
    hash=$(curl $url | sha256sum | head -c 64)
    echo "hash is $hash"
    echo -n "sha256=\"$hash\"; " >> operas.nix
    echo -n "url=\"$url\"; " >> operas.nix
    echo "};" >> operas.nix
done < <(cat versions)
echo "}" >> operas.nix
