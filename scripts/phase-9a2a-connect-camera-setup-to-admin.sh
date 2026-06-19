#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A2A - Connect Camera Setup to Admin"
echo "========================================"

FILE="apps/booth-ui/src/components/AdminPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: AdminPanel.tsx not found."
  exit 1
}

[ -f "apps/booth-ui/src/components/camera/CameraSetupPanel.tsx" ] || {
  echo "ERROR: CameraSetupPanel.tsx not found. Run 9A1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

if "CameraSetupPanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1

    lines.insert(insert_at, "import { CameraSetupPanel } from './camera';")
    text = "\n".join(lines) + "\n"

if "<CameraSetupPanel" not in text:
    if "<SessionLifecyclePanel" in text:
        text = re.sub(
            r"(\s*<SessionLifecyclePanel\s*/>\s*)",
            r"\1\n        <CameraSetupPanel />\n",
            text,
            count=1,
        )
    elif "<PaymentTransactionsPanel" in text:
        text = re.sub(
            r"(\s*<PaymentTransactionsPanel[^>]*/>\s*)",
            r"\1\n        <CameraSetupPanel />\n",
            text,
            count=1,
        )
    else:
        last_div = text.rfind("</div>")
        if last_div == -1:
            raise SystemExit("Could not find safe insert point.")

        text = text[:last_div] + "\n        <CameraSetupPanel />\n" + text[last_div:]

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "CameraSetupPanel" "$FILE" || {
  echo "ERROR: CameraSetupPanel missing in AdminPanel."
  exit 1
}

echo ""
grep -n "CameraSetupPanel\\|SessionLifecyclePanel\\|PaymentTransactionsPanel" "$FILE" || true

echo ""
echo "Phase 9A2A completed."
