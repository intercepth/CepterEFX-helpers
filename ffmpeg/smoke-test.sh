#!/usr/bin/env bash
# Runs the real kinds of command the Cepter EFX panel issues. Fails on the first error.
set -euo pipefail
FF="$1"; T="$(mktemp -d)"
run() { echo "== $*"; "$FF" -hide_banner -loglevel error -y "$@"; }
"$FF" -version | head -1
run -f lavfi -i testsrc=s=640x360:r=24:d=3 -f lavfi -i sine=f=440:d=3 -c:v libx264 -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:a aac -b:a 192k -movflags +faststart "$T/a.mp4"
run -i "$T/a.mp4" -vn -c:a libmp3lame -b:a 192k -ar 48000 "$T/a.mp3"
run -i "$T/a.mp4" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$T/a.wav"
run -i "$T/a.mp4" -vn -af "aresample=44100,atrim=start=0.5:end=2,asetpts=PTS-STARTPTS,apad=pad_dur=0.03" -ac 2 -ar 44100 -c:a pcm_f32le "$T/b.wav"
run -i "$T/a.mp4" -vn -af "aresample=44100,asetrate=48510,aresample=44100,areverse" -c:a pcm_f32le "$T/c.wav"
run -i "$T/a.mp4" -an -filter_complex "[0:v]mpdecimate,setpts=N/FRAME_RATE/TB[o]" -map "[o]" -c:v prores_ks -profile:v 2 -vendor apl0 -pix_fmt yuv422p10le "$T/p.mov"
run -i "$T/a.mp4" -an -sn -dn -vf "scale=320:-2,format=gray" -fps_mode passthrough -c:v rawvideo -f segment -segment_time 1 -segment_format rawvideo "$T/seg%03d.raw"
run -i "$T/a.mp4" -frames:v 1 -vf "scale=320:-2" "$T/f.png"
run -i "$T/a.mp4" -frames:v 1 "$T/f.jpg"
run -i "$T/a.mp4" -frames:v 1 "$T/f.tif"
run -f lavfi -i "color=c=black@0:s=640x360:r=1:d=1" -i "$T/a.mp4" -filter_complex "[1:v]scale=320:180:flags=lanczos,format=rgba,setpts=PTS-STARTPTS[l];[0:v]format=rgba[b];[b][l]overlay=x=10:y=10:format=auto,format=rgba" -frames:v 1 -update 1 "$T/s.png"
run -i "$T/a.mp4" -map 0:v:0 -c copy -f null -
run -i "$T/a.mp4" -i "$T/a.mp3" -filter_complex "[0:a][1:a]amix=inputs=2[mix]" -map "[mix]" -c:a pcm_f32le "$T/m.wav"
echo "all ok"; ls -l "$T" | head -30
