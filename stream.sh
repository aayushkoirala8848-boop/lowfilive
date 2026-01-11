#!/bin/bash

# 1. Create the playlist file with absolute paths
printf "file '%s'\n" "$(pwd)"/music/*.mp3 | sort > playlist.txt

# 2. Run FFmpeg with optimized settings for smooth streaming
# -stream_loop -1: Loops both video and audio indefinitely
# Note: -an removed from video input, we select streams via -map instead
ffmpeg -re -stream_loop -1 -i background.mp4 \
       -stream_loop -1 -f concat -safe 0 -i playlist.txt \
       -map 0:v:0 -map 1:a:0? \
       -c:v libx264 -preset ultrafast -tune zerolatency \
       -b:v 3000k -maxrate 3500k -bufsize 7000k \
       -r 24 -g 48 -keyint_min 48 \
       -pix_fmt yuv420p \
       -c:a aac -b:a 192k -ar 44100 -ac 2 \
       -shortest -fflags +genpts \
       -threads 0 \
       -flvflags no_duration_filesize \
       -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"