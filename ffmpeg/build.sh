#!/usr/bin/env bash
# Cross-builds a small, static, Windows x64 ffmpeg.exe on Ubuntu (mingw-w64).
# Everything is pinned below; the exact tarballs are also attached to each release
# (GPL source offer). Run from the repo root:  bash ffmpeg/build.sh
set -euo pipefail

FFMPEG_TAG="n8.1.3"
X264_COMMIT="b35605ace3ddf7c1a5d67a2eb553f034aef41d55"     # x264 'stable' branch
LAME_VER="3.100"
ZLIB_VER="1.3.1"

ROOT="$(pwd)"
WORK="$ROOT/_work"; PREFIX="$WORK/prefix"; SRC="$WORK/src"; OUT="$ROOT/_out"
HOST=x86_64-w64-mingw32
mkdir -p "$SRC" "$PREFIX" "$OUT"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
CFLAGS_BASE="-O2 -ffunction-sections -fdata-sections"

fetch() { # url dest
  for i in 1 2 3 4; do curl -fsSL --retry 3 -o "$2" "$1" && return 0; sleep 5; done
  echo "download failed: $1" >&2; return 1
}

cd "$SRC"
fetch "https://github.com/madler/zlib/releases/download/v${ZLIB_VER}/zlib-${ZLIB_VER}.tar.gz" zlib.tar.gz
fetch "https://downloads.sourceforge.net/lame/lame-${LAME_VER}.tar.gz" lame.tar.gz
fetch "https://code.videolan.org/videolan/x264/-/archive/${X264_COMMIT}/x264-${X264_COMMIT}.tar.gz" x264.tar.gz
fetch "https://github.com/FFmpeg/FFmpeg/archive/refs/tags/${FFMPEG_TAG}.tar.gz" ffmpeg.tar.gz
for t in zlib lame x264 ffmpeg; do mkdir -p $t && tar xzf $t.tar.gz -C $t --strip-components=1; done

# zlib (needed by PNG, TIFF, compressed MOV atoms)
( cd zlib && CC=$HOST-gcc AR=$HOST-ar RANLIB=$HOST-ranlib CFLAGS="$CFLAGS_BASE" \
  ./configure --static --prefix="$PREFIX" && make -j"$(nproc)" && make install )

# LAME (MP3 encoder)
( cd lame && ./configure --host=$HOST --prefix="$PREFIX" --disable-shared --enable-static \
  --disable-frontend --disable-decoder --disable-gtktest CFLAGS="$CFLAGS_BASE" \
  && make -j"$(nproc)" && make install )

# x264 (H.264 encoder, GPL)
( cd x264 && ./configure --host=$HOST --cross-prefix=$HOST- --prefix="$PREFIX" \
  --enable-static --disable-cli --disable-opencl --disable-avs --disable-swscale \
  --disable-lavf --disable-ffms --disable-gpac --disable-lsmash --bit-depth=8 \
  --extra-cflags="$CFLAGS_BASE" && make -j"$(nproc)" && make install )

# FFmpeg: ALL decoders, demuxers, parsers, bitstream filters and filters stay on
# (users drop in any footage and the panel uses many filters). Encoders, muxers,
# protocols, devices and hardware paths are cut to what the panel actually calls.
cd "$SRC/ffmpeg"
./configure \
  --arch=x86_64 --target-os=mingw32 --cross-prefix=$HOST- --pkg-config=pkg-config \
  --prefix="$PREFIX/ff" --pkg-config-flags=--static \
  --extra-cflags="-I$PREFIX/include $CFLAGS_BASE" \
  --extra-ldflags="-L$PREFIX/lib -static -Wl,--gc-sections" \
  --enable-gpl --enable-version3 --enable-libx264 --enable-libmp3lame --enable-zlib \
  --disable-autodetect --disable-debug --disable-doc --disable-network \
  --disable-ffplay --disable-ffprobe --disable-hwaccels --disable-indevs --disable-outdevs \
  --enable-indev=lavfi \
  --disable-encoders \
  --enable-encoder=libx264,libmp3lame,aac,prores_ks,png,mjpeg,tiff,pcm_s16le,pcm_s24le,pcm_f32le,rawvideo \
  --disable-muxers \
  --enable-muxer=mp4,mov,mp3,wav,image2,segment,rawvideo,null,pcm_s16le,pcm_f32le,s16le,f32le \
  --disable-protocols --enable-protocol=file,pipe
make -j"$(nproc)"
$HOST-strip --strip-all ffmpeg.exe
cp ffmpeg.exe "$OUT/ffmpeg.exe"

# Sources for the GPL source offer, shipped with every release
tar czf "$OUT/ffmpeg-sources.tar.gz" -C "$SRC" zlib.tar.gz lame.tar.gz x264.tar.gz ffmpeg.tar.gz
ls -l "$OUT"
