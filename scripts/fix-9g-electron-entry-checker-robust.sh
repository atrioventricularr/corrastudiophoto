#!/usr/bin/env bash
set -euo pipefail

LATEST_RELEASE="$(ls -td release/corra-booth-* 2>/dev/null | head -1)"

if [ -z "$LATEST_RELEASE" ]; then
  echo "No release folder found."
  exit 1
fi

SOURCE_DIR="apps/desktop-electron"

copy_entries_to() {
  local target="$1"
  mkdir -p "$target"

  for file in \
    main.cjs \
    index.cjs \
    preload.cjs \
    package.json \
    corra-disk-persistence.cjs \
    corra-disk-preload.cjs \
    corra-hardware-diagnostics.cjs \
    corra-hardware-preload.cjs
  do
    if [ -f "$SOURCE_DIR/$file" ]; then
      cp "$SOURCE_DIR/$file" "$target/$file"
      echo "✅ copied $file -> $target"
    fi
  done
}

copy_entries_to "$LATEST_RELEASE/apps/desktop-electron"
copy_entries_to "$LATEST_RELEASE/desktop-electron"
copy_entries_to "$LATEST_RELEASE/electron"

cat > scripts/check-corra-release-candidate.sh <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

LATEST_RELEASE="$(ls -td release/corra-booth-* 2>/dev/null | head -1)"

echo "Corra Release Candidate Check"
echo "============================="

if [ -z "$LATEST_RELEASE" ]; then
  echo "❌ release folder"
  exit 1
fi

has_file() {
  local label="$1"
  shift

  for file in "$@"; do
    if [ -f "$file" ]; then
      echo "✅ $label"
      return 0
    fi
  done

  echo "❌ $label"
  return 1
}

has_dir() {
  local label="$1"
  shift

  for dir in "$@"; do
    if [ -d "$dir" ]; then
      echo "✅ $label"
      return 0
    fi
  done

  echo "❌ $label"
  return 1
}

has_file "booth package" \
  "$LATEST_RELEASE/apps/booth-ui/package.json" \
  "$LATEST_RELEASE/booth-ui/package.json"

has_dir "booth dist" \
  "$LATEST_RELEASE/apps/booth-ui/dist" \
  "$LATEST_RELEASE/booth-ui/dist" \
  "$LATEST_RELEASE/dist"

has_dir "desktop electron" \
  "$LATEST_RELEASE/apps/desktop-electron" \
  "$LATEST_RELEASE/desktop-electron" \
  "$LATEST_RELEASE/electron"

has_file "electron main" \
  "$LATEST_RELEASE/apps/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/electron/main.cjs" \
  "$LATEST_RELEASE/electron/index.cjs"

has_file "electron preload" \
  "$LATEST_RELEASE/apps/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/electron/preload.cjs"

has_file "disk bridge" \
  "$LATEST_RELEASE/apps/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/electron/corra-disk-persistence.cjs"

has_file "hardware bridge" \
  "$LATEST_RELEASE/apps/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/electron/corra-hardware-diagnostics.cjs"

has_file "9G docs" \
  "$LATEST_RELEASE/docs/phase-9g-release-candidate-checklist.md" \
  "docs/phase-9g-release-candidate-checklist.md"

echo ""
echo "Latest release:"
echo "$LATEST_RELEASE"
CHECK

chmod +x scripts/check-corra-release-candidate.sh

echo ""
echo "Latest release:"
echo "$LATEST_RELEASE"

echo ""
echo "Electron entry files found:"
find "$LATEST_RELEASE" -maxdepth 4 -type f \( \
  -name "main.cjs" -o \
  -name "index.cjs" -o \
  -name "preload.cjs" -o \
  -name "corra-disk-persistence.cjs" -o \
  -name "corra-hardware-diagnostics.cjs" \
\) | sort
