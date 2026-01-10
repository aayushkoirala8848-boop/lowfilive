#!/bin/bash

# 1. Create the playlist file
printf "file '%s'\n" music/*.mp3 | sort > playlist.txt

# 2. Run FFmpeg
# -an: This flag ignores the audio track of the background video
ffmpeg -re -stream_loop -1 -i background.mp4 -an \
       -f concat -safe 0 -i playlist.txt \
       -c:v libx264 -preset veryfast -b:v 3000k -maxrate 3000k -bufsize 6000k \
       -framerate 24 -g 48 -pix_fmt yuv420p \
       -c:a aac -b:a 128k -ar 44100 -ac 2 \
       -map 0:v:0 -map 1:a:0 \
       -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"