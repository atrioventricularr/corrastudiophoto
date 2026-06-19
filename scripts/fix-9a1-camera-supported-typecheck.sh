#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/camera/useCameraDevices.ts"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found"
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/useCameraDevices.ts")
text = path.read_text()

old = """function isCameraSupported(): boolean {
  return Boolean(
    typeof navigator !== 'undefined' &&
      navigator.mediaDevices &&
      navigator.mediaDevices.getUserMedia &&
      navigator.mediaDevices.enumerateDevices,
  );
}"""

new = """function isCameraSupported(): boolean {
  if (typeof navigator === 'undefined') {
    return false;
  }

  const mediaDevices = navigator.mediaDevices;

  return Boolean(
    mediaDevices &&
      typeof mediaDevices.getUserMedia === 'function' &&
      typeof mediaDevices.enumerateDevices === 'function',
  );
}"""

if old not in text:
    raise SystemExit("Could not find old isCameraSupported block. Please paste the first 20 lines of useCameraDevices.ts.")

text = text.replace(old, new)

path.write_text(text)
print("PATCHED:", path)
PY

echo ""
echo "Done. Now run:"
echo "pnpm --filter @corra/booth-ui typecheck"
