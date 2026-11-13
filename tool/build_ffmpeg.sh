#!/usr/bin/env bash
# Builds the FFmpeg component Tune ships (docs/licensing.md §3).
#
# The binary is GPL-2.0-or-later because configure runs with --enable-gpl.
# The archive therefore carries COPYING.GPLv2 and README.tune.txt, which
# names the exact source tarball and the configure line. That pair is the
# written offer of corresponding source; keep it intact when publishing.
#
# Usage: tool/build_ffmpeg.sh [output-directory]
set -euo pipefail

version=8.0.1
channel=components-ffmpeg-$version
out_dir=${1:-dist}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cd "$work"
source_tarball=ffmpeg-$version.tar.xz
curl -fL -o "$source_tarball" "https://ffmpeg.org/releases/$source_tarball"
source_sha256=$(sha256sum "$source_tarball" | cut -d' ' -f1)
tar -xf "$source_tarball"

cd "ffmpeg-$version"
./configure \
  --prefix=/usr \
  --enable-gpl \
  --enable-static \
  --disable-shared \
  --disable-doc \
  --disable-debug \
  --disable-network \
  --disable-autodetect \
  --enable-small \
  --extra-version=tune
make -j"$(nproc)"
make DESTDIR="$work/root" install

package=$work/package
mkdir -p "$package"
cp "$work/root/usr/bin/ffmpeg" "$package/ffmpeg"
cp COPYING.GPLv2 "$package/COPYING.GPLv2"
cat > "$package/README.tune.txt" <<EOF
FFmpeg $version, GPL-2.0-or-later, static Ubuntu x86-64 build.

Source:   https://ffmpeg.org/releases/$source_tarball
sha256:   $source_sha256
License:  https://ffmpeg.org/legal.html
GPLv2:    COPYING.GPLv2 in this archive

Configure line:
./configure --prefix=/usr --enable-gpl --enable-static --disable-shared \\
  --disable-doc --disable-debug --disable-network --disable-autodetect \\
  --enable-small --extra-version=tune

The binary is unmodified; Tune only runs it as a subprocess to turn m4a and
similar files into 16 kHz mono WAV. Build script: tool/build_ffmpeg.sh.
EOF

mkdir -p "$out_dir"
archive="$out_dir/ffmpeg-$version-linux-x64-gpl.tar.xz"
tar -C "$package" -cJf "$archive" .
echo "archive:  $archive"
echo "bytes:    $(stat -c %s "$archive")"
echo "sha256:   $(sha256sum "$archive" | cut -d' ' -f1)"
echo "Upload to GitHub release '$channel' and pin the bytes and sha256 in"
echo "LocalComponentRegistry.ffmpeg."
