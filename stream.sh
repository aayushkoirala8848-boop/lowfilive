#!/bin/bash

set -e

# Navigate to script directory
cd "$(dirname "$0")"

echo "=== Starting 24/7 Lo-Fi Stream ==="
echo "Current directory: $(pwd)"

# 1. Create the playlist file with proper escaping for filenames with spaces
echo "Creating playlist..."
> playlist.txt
for f in music/*.mp3; do
    if [ -f "$f" ]; then
        echo "file '$(pwd)/$f'" >> playlist.txt
    fi
done

# Verify playlist was created
if [ ! -s playlist.txt ]; then
    echo "ERROR: No MP3 files found in music folder!"
    exit 1
fi

echo "Playlist created with $(wc -l < playlist.txt) tracks"
cat playlist.txt

# 2. Verify video file exists
if [ ! -f "background.mp4" ]; then
    echo "ERROR: background.mp4 not found!"
    exit 1
fi

echo "Starting stream to YouTube..."

# 3. Run FFmpeg with YouTube-optimized settings
# - Low latency settings for minimal buffering
# - YouTube recommended: 1080p30 or 720p30 for 24/7 streams
# - CBR (Constant Bit Rate) is better for streaming stability
# - GOP size = 2 seconds (framerate * 2) for YouTube compatibility

ffmpeg -loglevel warning -stats \
    -re \
    -stream_loop -1 -i "background.mp4" \
    -stream_loop -1 -f concat -safe 0 -i playlist.txt \
    -map 0:v:0 -map 1:a:0 \
    -c:v libx264 \
    -preset veryfast \
    -tune zerolatency \
    -profile:v high \
    -level 4.1 \
    -b:v 4500k \
    -minrate 4500k \
    -maxrate 4500k \
    -bufsize 4500k \
    -r 30 \
    -g 60 \
    -keyint_min 60 \
    -sc_threshold 0 \
    -pix_fmt yuv420p \
    -c:a aac \
    -b:a 128k \
    -ar 44100 \
    -ac 2 \
    -af "aresample=async=1:first_pts=0" \
    -fflags +genpts+discardcorrupt \
    -flags +global_header \
    -max_muxing_queue_size 1024 \
    -f flv \
    "rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"

echo "Stream ended."