#!/usr/bin/env bash
set -euo pipefail

MAIN_REQUIRE="require('./corra-hardware-diagnostics.cjs');"
PRELOAD_REQUIRE="require('./corra-hardware-preload.cjs');"

patch_require_once() {
  local file="$1"
  local line="$2"

  if [ ! -f "$file" ]; then
    echo "SKIP missing: $file"
    return
  fi

  if grep -qF "$line" "$file"; then
    echo "OK already patched: $file"
    return
  fi

  cp "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"

  python - "$file" "$line" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
line = sys.argv[2]
text = path.read_text()

if text.startswith("#!"):
    parts = text.split("\n", 1)
    text = parts[0] + "\n" + line + "\n" + (parts[1] if len(parts) > 1 else "")
else:
    text = line + "\n" + text

path.write_text(text)
PY

  echo "PATCHED: $file"
}

patch_require_once "apps/desktop-electron/main.cjs" "$MAIN_REQUIRE"
patch_require_once "apps/desktop-electron/index.cjs" "$MAIN_REQUIRE"
patch_require_once "apps/desktop-electron/preload.cjs" "$PRELOAD_REQUIRE"

echo ""
grep -R \
  --exclude-dir=node_modules \
  --exclude-dir=dist \
  --exclude-dir=.vite \
  "corra-hardware-diagnostics\|corra-hardware-preload" \
  -n apps/desktop-electron || true
