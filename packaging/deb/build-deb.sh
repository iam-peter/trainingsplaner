#!/bin/sh
# Builds the Debian package from the AppDir linuxdeploy fills for the
# AppImage. Only Qt and its ICU come along, in /opt/trainingsplaner:
# distributions ship a Qt too old for it. Every other library comes from
# the system and becomes a dependency, which dpkg-shlibdeps works out, so
# this has to run on the oldest system the package is for.
#
# Usage: build-deb.sh <AppDir> <version> <output.deb>
set -eu

if [ $# -ne 3 ]; then
    echo "Usage: $0 <AppDir> <version> <output.deb>" >&2
    exit 2
fi
appdir=$1
version=$2
output=$3
logo=$(cd "$(dirname "$0")/../../logo" && pwd)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
# Under debian/ dpkg-shlibdeps takes the libraries in it as the package's own
root=$work/debian/trainingsplaner
prefix=$root/opt/trainingsplaner

mkdir -p "$prefix/lib" "$root/usr/bin" "$root/DEBIAN"
for dir in bin plugins qml translations; do
    if [ -d "$appdir/usr/$dir" ]; then
        cp -a "$appdir/usr/$dir" "$prefix/"
    fi
done
cp -a "$appdir"/usr/lib/libQt6* "$prefix/lib/"
cp -a "$appdir"/usr/lib/libicu* "$prefix/lib/" 2>/dev/null || true
ln -s /opt/trainingsplaner/bin/trainingsplaner "$root/usr/bin/trainingsplaner"
install -Dm644 "$logo/trainingsplaner.desktop" "$root/usr/share/applications/trainingsplaner.desktop"
install -Dm644 "$logo/trainingsplaner.svg" "$root/usr/share/icons/hicolor/scalable/apps/trainingsplaner.svg"
chmod -R u+rwX,go+rX,go-w "$root"

printf 'Source: trainingsplaner\n\nPackage: trainingsplaner\nArchitecture: amd64\n' > "$work/debian/control"
libs=$(cd "$work" && find debian/trainingsplaner/opt -type f \( -name '*.so*' -o -path '*/bin/trainingsplaner' \) \
    -exec dpkg-shlibdeps -O -l"$prefix/lib" {} + | sed -n 's/^shlibs:Depends=//p')

cat > "$root/DEBIAN/control" <<EOF
Package: trainingsplaner
Version: $version
Architecture: amd64
Maintainer: Henning Gruendl <henning.gruendl@qt.io>
Installed-Size: $(du -sk "$root" | cut -f1)
Depends: $libs
Section: misc
Priority: optional
Homepage: https://iam-peter.github.io/trainingsplaner/
Description: Weekly training planner for weightlifting
 Plans weekly training for weightlifters: sessions with weight steps,
 the load figures WH, MHG and BW per exercise and group, and printed
 week plans.
EOF

dpkg-deb --root-owner-group -Zxz -b "$root" "$output"
