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
# Frame Interpolation: scene score branch ends in "-f null -" (needs wrapped_avframe), loop join via concat filter
run -i "$T/a.mp4" -i "$T/a.mp4" -an -sn -filter_complex "[0:v:0]fps=24,format=rgb24[c0];[1:v:0]fps=24,format=rgb24[c1];[c0]trim=end_frame=20,setpts=PTS-STARTPTS[c0t];[c1]trim=end_frame=1,setpts=PTS-STARTPTS[c1t];[c0t][c1t]concat=n=2:v=1:a=0[cj];[cj]tpad=stop_mode=clone:stop=2,split=2[v][s];[s]scale=320:-2:flags=fast_bilinear,format=yuv420p,select='gte(scene,0)',metadata=print[sc]" -map "[v]" -frames:v 22 -compression_level 1 -start_number 1 "$T/l%05d.png" -map "[sc]" -frames:v 22 -f null -
# Dead Frames style decode-only pass
run -i "$T/a.mp4" -map 0:v:0 -an -f null -
# concat demuxer join (stream copy)
printf "file 'a.mp4'
file 'a.mp4'
" > "$T/list.txt"   # relative names: resolved against the list's own folder
file '%s'
" "$T/a.mp4" "$T/a.mp4" > "$T/list.txt"
run -f concat -safe 0 -i "$T/list.txt" -map 0:v:0 -c copy -f mp4 "$T/joined.mp4"
# Frame Interpolation final encode from a PNG sequence
run -f lavfi -i testsrc=s=320x180:r=24:d=1 -start_number 1 "$T/s%03d.png"
run -framerate 24 -start_number 1 -i "$T/s%03d.png" -vf "scale=in_range=full:out_range=tv:out_color_matrix=bt709:flags=accurate_rnd+full_chroma_int,format=yuv420p" -c:v libx264 -crf 14 -preset medium -color_range tv -movflags +faststart -f mp4 "$T/fi.mp4"
echo "all ok"; ls -l "$T" | head -30
