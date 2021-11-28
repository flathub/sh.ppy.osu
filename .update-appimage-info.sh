#!/bin/bash
# Temporary ugly code for maintaining purposes
latest="$(curl -L -s https://api.github.com/repos/ppy/osu/releases/latest | jq '.tag_name | sub("^v"; "")' -r)"
current="$(grep -o "download/[^\"].*/osu.AppImage" sh.ppy.osu.yaml | sed 's/^download\///;s/\/osu.AppImage//')"
date="$(echo "$latest" | sed -e 's/\./-/g' -e 's/.\{7\}/&\-/' | cut -c 1-10)"
echo "current: $current"
echo "latest:  $latest"
if [ "$current" == "$latest" ]; then
        echo "There is no new version"
        exit 1
fi
sleep 3
rm -f osu.AppImage
url="https://github.com/ppy/osu/releases/download/$latest/osu.AppImage"
curl -L --progress-bar -o osu.AppImage "$url"
sha256sum="$(sha256sum osu.AppImage | cut -d " " -f 1)"
sed "s/\/download\/$current\/osu.AppImage/\/download\/$latest\/osu.AppImage/" -i sh.ppy.osu.yaml
sed "s/sha256: .*/sha256: $sha256sum/" -i sh.ppy.osu.yaml
sed '/<releases>/a \ \ \ \ \ \ \ \ <release version="'$latest'" date="'$date'"\/>' -i sh.ppy.osu.appdata.xml
rm -f osu.AppImage
