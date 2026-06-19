#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

# Remove repeated same option lines inside render option objects.
lines = text.splitlines()
out = []
in_render_options = False
seen_keys = set()

for line in lines:
    stripped = line.strip()

    if (
        "renderPrintReadyTemplateToCanvas({" in line
        or "renderFinalTemplateToCanvas({" in line
    ):
        in_render_options = True
        seen_keys = set()
        out.append(line)
        continue

    if in_render_options:
        match = re.match(r"^([A-Za-z0-9_]+):", stripped)

        if match:
            key = match.group(1)

            if key in seen_keys:
                continue

            seen_keys.add(key)

        if stripped in {");", "});"} or stripped.startswith("});"):
            in_render_options = False
            seen_keys = set()

    out.append(line)

path.write_text("\n".join(out) + "\n")
print("Fixed duplicate render options.")
PY

echo ""
echo "Preview around error area:"
nl -ba "$FILE" | sed -n '30,55p'
