#!/usr/bin/env bash
#
# Resolve a YouTube channel handle/URL to a channel ID, then fetch the latest
# N video IDs and titles via yt-dlp.
#
# Output manifest TSV columns: <video_id>\t<title>\t<video_id>
#   (canonical_id = video_id, payload = video_id; bulk_add youtube mode
#    constructs the URL from the payload)
#
# Usage: youtube_channel.sh <handle_or_url> <count> <output_tsv>
# Example: youtube_channel.sh @StumpyNubs 100 stumpy_videos.tsv
#
# Prints the resolved channel ID to stdout on success (last line) so the
# caller can capture it. Errors go to stderr and exit non-zero.
#
set -uo pipefail

HANDLE="${1:?handle or URL required}"
COUNT="${2:?count required}"
OUTPUT="${3:?output TSV path required}"

# Normalize: accept @handle, full URL, or bare handle
case "$HANDLE" in
  http*) URL="$HANDLE" ;;
  @*) URL="https://www.youtube.com/$HANDLE" ;;
  *) URL="https://www.youtube.com/@$HANDLE" ;;
esac

# Strip trailing /videos if present, we'll add it
URL="${URL%/videos}"
URL="${URL%/}"

# Resolve channel ID (UCxxxxxxxxx) by scraping the channel page
CHANNEL_ID=$(curl -fsS "$URL" 2>/dev/null | grep -oE '"externalId":"UC[A-Za-z0-9_-]+"' | head -1 | sed -E 's/.*"(UC[^"]+)".*/\1/')
if [[ -z "$CHANNEL_ID" ]]; then
  CHANNEL_ID=$(curl -fsS "$URL" 2>/dev/null | grep -oE '"channelId":"UC[A-Za-z0-9_-]+"' | head -1 | sed -E 's/.*"(UC[^"]+)".*/\1/')
fi
[[ -z "$CHANNEL_ID" ]] && { echo "ERROR: could not resolve channel ID for $URL" >&2; exit 1; }

# Fetch latest N videos. --flat-playlist is fast (~5s for 100 videos) and
# returns just metadata without downloading.
yt-dlp --flat-playlist \
  --print "%(id)s	%(title)s	%(id)s" \
  --playlist-end "$COUNT" \
  "$URL/videos" \
  > "$OUTPUT" 2>/dev/null \
  || { echo "ERROR: yt-dlp failed for $URL" >&2; exit 1; }

ROWS=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "FETCHED: $ROWS videos -> $OUTPUT" >&2
echo "$CHANNEL_ID"
