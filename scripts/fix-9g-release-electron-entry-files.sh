#!/usr/bin/env bash
set -euo pipefail

LATEST_RELEASE="$(ls -td release/corra-booth-* 2>/dev/null | head -1)"

if [ -z "$LATEST_RELEASE" ]; then
  echo "No release folder found."
  exit 1
fi

TARGET_DIR="$LATEST_RELEASE/apps/desktop-electron"
SOURCE_DIR="apps/desktop-electron"

mkdir -p "$TARGET_DIR"

copy_if_exists() {
  local file="$1"

  if [ -f "$SOURCE_DIR/$file" ]; then
    cp "$SOURCE_DIR/$file" "$TARGET_DIR/$file"
    echo "✅ copied $file"
  else
    echo "⚠️ missing source $SOURCE_DIR/$file"
  fi
}

copy_if_exists "main.cjs"
copy_if_exists "index.cjs"
copy_if_exists "preload.cjs"
copy_if_exists "package.json"
copy_if_exists "corra-disk-persistence.cjs"
copy_if_exists "corra-disk-preload.cjs"
copy_if_exists "corra-hardware-diagnostics.cjs"
copy_if_exists "corra-hardware-preload.cjs"

echo ""
echo "Latest release:"
echo "$LATEST_RELEASE"

echo ""
echo "Electron files in release:"
find "$TARGET_DIR" -maxdepth 1 -type f | sort
