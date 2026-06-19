#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found"
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

lines = text.splitlines()
out = []

in_render_call = False
seen_keys = set()

for line in lines:
    stripped = line.strip()

    if (
        "renderPrintReadyTemplateToCanvas({" in line
        or "renderFinalTemplateToCanvas({" in line
    ):
        in_render_call = True
        seen_keys = set()
        out.append(line)
        continue

    if in_render_call:
        match = re.match(r"^([A-Za-z0-9_]+):", stripped)

        if match:
            key = match.group(1)

            if key in seen_keys:
                print(f"Removed duplicate option: {key}")
                continue

            seen_keys.add(key)

        if stripped.startswith("});") or stripped == "});":
            in_render_call = False
            seen_keys = set()

    out.append(line)

path.write_text("\n".join(out) + "\n")
print("Done fixing duplicate render options.")
PY

echo ""
echo "Preview line 30-55:"
nl -ba "$FILE" | sed -n '30,55p'
