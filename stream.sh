#!/bin/bash

# 1. Create the playlist file with proper formatting for spaces/special characters
# This finds all mp3s, sorts them, and adds "file 'filename'" to each line
printf "file '%s'\n" music/*.mp3 | sort > playlist.txt

# 2. Run FFmpeg
# -stream_loop -1 (first one): Loops your video background forever
# -stream_loop -1 (second one): Loops your entire song list forever
ffmpeg -re -stream_loop -1 -i background.mp4 \
       -stream_loop -1 -f concat -safe 0 -i playlist.txt \
       -c:v libx264 -preset veryfast -b:v 3000k -maxrate 3000k -bufsize 6000k \
       -framerate 24 -g 48 -pix_fmt yuv420p \
       -c:a aac -b:a 128k -ar 44100 \
       -f flv "rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY"