Windows x64 `ffmpeg.exe` for the Cepter EFX panel. Static single executable, GPL (x264).

- `ffmpeg-win64.zip` - `ffmpeg.exe` plus the licence notice.
- `ffmpeg-sources.tar.gz` - the exact FFmpeg, x264, LAME and zlib sources used (GPL source offer).
- Build: `ffmpeg/build.sh`, run by `.github/workflows/ffmpeg.yml`. All decoders, demuxers and filters are kept; encoders and muxers are limited to what the panel calls.
