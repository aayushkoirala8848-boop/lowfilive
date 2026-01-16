#!/bin/bash

set -euo pipefail

# Move to script directory so relative paths work
cd "$(dirname "$0")"

echo "=== Starting 24/7 Lo-Fi Stream ==="
echo "Current directory: $(pwd)"

# Build playlist safely (handles spaces)
echo "Creating playlist..."
> playlist.txt
for f in music/*.mp3; do
    if [ -f "$f" ]; then
        # Use absolute path and single quotes around path
        echo "file '$(pwd)/$f'" >> playlist.txt
    fi
done

# If no mp3 files exist, create an empty playlist and fall back to silent audio later
if [ ! -s playlist.txt ]; then
    echo "WARNING: No MP3 files found in music/; falling back to silent audio."
else
    echo "Playlist created with $(wc -l < playlist.txt) tracks"
fi

# Verify video file exists
if [ ! -f "background.mp4" ]; then
    echo "ERROR: background.mp4 not found!"
    exit 1
fi

STREAM_URL="rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"

logfile="ffmpeg_stream.log"

trap 'echo "Stopping stream loop"; exit 0' SIGINT SIGTERM

while true; do
    echo "========== $(date -u +"%Y-%m-%d %H:%M:%S UTC") - Starting ffmpeg instance ==========" | tee -a "$logfile"

    # Choose audio source: playlist if present, otherwise a silent source
    if [ -s playlist.txt ]; then
        AUDIO_INPUT=( -stream_loop -1 -f concat -safe 0 -i playlist.txt )
    else
        # anullsrc provides silent stereo audio at 44100 Hz
        AUDIO_INPUT=( -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=44100" )
    fi

    # Run ffmpeg and capture exit code
    ffmpeg -hide_banner -loglevel warning -stats \
        -re \
        -stream_loop -1 -i "background.mp4" \
        "${AUDIO_INPUT[@]}" \
        -map 0:v:0 -map 1:a:0 \
        -c:v libx264 \
        -preset veryfast \
        -tune zerolatency \
        -profile:v high \
        -level 4.1 \
        -b:v 2500k \
        -minrate 2500k \
        -maxrate 2500k \
        -bufsize 3000k \
        -r 30 \
        -g 60 \
        -keyint_min 60 \
        -sc_threshold 0 \
        -bf 0 \
        -vsync 1 \
        -pix_fmt yuv420p \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -ac 2 \
        -af "aresample=async=1:first_pts=0" \
        -fflags +genpts+discardcorrupt \
        -flags +global_header \
        -max_muxing_queue_size 2048 \
        -f flv "$STREAM_URL" 2>&1 | tee -a "$logfile"

    rc=${PIPESTATUS[0]:-0}
    echo "ffmpeg exited with code $rc" | tee -a "$logfile"

    # If ffmpeg exited cleanly (0), break; otherwise wait and restart
    if [ "$rc" -eq 0 ]; then
        echo "ffmpeg ended normally. Exiting loop." | tee -a "$logfile"
        break
    fi

    echo "ffmpeg crashed or was killed, restarting in 8 seconds..." | tee -a "$logfile"
    sleep 8
done

echo "Stream script finished." | tee -a "$logfile"