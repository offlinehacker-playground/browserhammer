#!/usr/bin/env bash
echo "{" > chromiums.nix
for version in $@; do
    position=$(curl https://omahaproxy.appspot.com/revision.json\?version\=$version | python -c "import json, sys;obj=json.load(sys.stdin);print obj['chromium_base_position'];")
    echo "fetching hash for chromium $version"
    echo -n "\"$version\" = { " >> chromiums.nix
    hash=$(curl "http://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/$position/chrome-linux.zip" | sha256sum | head -c 64)
    echo "hash is $hash"
    echo -n "sha256=\"$hash\"; " >> chromiums.nix
    echo -n "url=\"http://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_x64/$position/chrome-linux.zip\"; " >> chromiums.nix
    echo "};" >> chromiums.nix
done
echo "}" >> chromiums.nix
