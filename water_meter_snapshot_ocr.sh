#!/usr/bin/env bash
set -e

# Install ImageMagick only if "magick" is not available
if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick not found, installing..."
  apk add --no-cache imagemagick
fi

SNAP="/config/www/water_meter_snapshot.jpg"
TEMPLATE="/config/www/water_meter_template.png"
WORK="/config/www/water_meter_ssocr.png"

# 1. Find where the template appears in the current snapshot
#    compare returns 1 when images differ, which is normal for us,
#    so we must NOT let set -e kill the script here.
set +e
match=$(compare -metric RMSE "$SNAP" "$TEMPLATE" -subimage-search null: 2>&1)
status=$?
set -e

# If compare actually errored (status >= 2), bail out
if [ "$status" -ge 2 ] || [ -z "$match" ]; then
  echo "compare failed (status=$status), output: $match" >&2
  exit 1
fi

# Extract "x,y" after "@ "
coords=${match#*@ }
coords=${coords%% *}

x=${coords%%,*}
y=${coords##*,}

# Optional: debug
echo "match: $match" >&2
echo "coords: $coords, x=$x, y=$y" >&2

# 2. Crop around that location (same size as template)
magick "$SNAP" \
  -crop 270x52+"$x"+"$y" +repage \
  -colorspace Gray -auto-level \
  -lat 30x52-5% +dither -type bilevel \
  "$WORK"
