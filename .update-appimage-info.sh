#!/bin/bash

get_latest_version() {
    echo "$(curl -L -s https://api.github.com/repos/ppy/osu/releases/latest | jq '.tag_name' -r | sed 's/^v//')"
}

get_current_version() {
    echo "$(grep -o "download/[^\"].*/osu.AppImage" sh.ppy.osu.yaml | sed 's/^download\///;s/\/osu.AppImage//')"
}

format_date_from_version() {
    echo "${1//./-}" | cut -c 1-10
}

update_appimage() {
    local latest_version="$1"
    local url="https://github.com/ppy/osu/releases/download/v${latest_version}/osu.AppImage"
    curl -L --progress-bar -o osu.AppImage "${url}"
    local sha256sum=$(sha256sum osu.AppImage | cut -d " " -f 1)
    sed -i "s/\/download\/$current_version\/osu.AppImage/\/download\/v$latest_version\/osu.AppImage/" sh.ppy.osu.yaml
    sed -i "s/sha256: .*/sha256: $sha256sum/" sh.ppy.osu.yaml
    sed -i "/<releases>/a \ \ \ \ \ \ \ \ <release version=\"$latest_version\" date=\"$(format_date_from_version $latest_version)\"\/>" sh.ppy.osu.appdata.xml
    rm -f osu.AppImage
}

# Main
latest_version=$(get_latest_version)
current_version=$(get_current_version)

echo "Current version: $current_version"
echo "Latest version:  $latest_version"

if [ "$current_version" == "$latest_version" ]; then
    echo "There is no new version."
    exit 1
else
    echo "Updating osu! to version $latest_version..."
    update_appimage "$latest_version"
    echo "Update complete."
fi
