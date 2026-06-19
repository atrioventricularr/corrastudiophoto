#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/camera/CameraLivePreview.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/camera/CameraLivePreview.tsx")
text = path.read_text()

# 1. Add useLayouts import.
if "useLayouts" not in text:
    lines = text.splitlines()
    insert_at = 0

    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1

    lines.insert(insert_at, "import { useLayouts } from '../layouts';")
    text = "\n".join(lines) + "\n"

# 2. Add hook before first return.
if "const { guideSettings } = useLayouts();" not in text:
    text = text.replace(
        "  return (",
        "  const { guideSettings } = useLayouts();\n\n  return (",
        1,
    )

# 3. Add data attribute to the main preview wrapper.
if "data-mirror-preview" not in text:
    pattern = re.compile(
        r'(<div[^>]*className=["\'][^"\']*relative[^"\']*overflow-hidden[^"\']*["\'][^>]*)>',
        re.MULTILINE,
    )

    match = pattern.search(text)

    if not match:
        raise SystemExit(
            "Could not find main preview wrapper with relative overflow-hidden."
        )

    replacement = (
        match.group(1)
        + "\n      data-mirror-preview={guideSettings.mirrorPreview ? 'true' : 'false'}>"
    )

    text = text[:match.start()] + replacement + text[match.end():]

path.write_text(text)
print("PATCH:", path)
PY

CSS="apps/booth-ui/src/index.css"

if [ ! -f "$CSS" ]; then
  CSS="apps/booth-ui/src/App.css"
fi

[ -f "$CSS" ] || {
  echo "ERROR: CSS file not found."
  exit 1
}

grep -q "data-mirror-preview" "$CSS" || cat >> "$CSS" <<'CSS'

/* Corra Booth camera preview mirror mode */
[data-mirror-preview="true"] video {
  transform: scaleX(-1);
  transform-origin: center;
}
CSS

echo ""
echo "Relevant CameraLivePreview lines:"
grep -n "useLayouts\\|guideSettings\\|data-mirror-preview" "$FILE" || true

echo ""
echo "Relevant CSS lines:"
grep -n "data-mirror-preview" "$CSS" || true

echo ""
echo "9A3B done."
