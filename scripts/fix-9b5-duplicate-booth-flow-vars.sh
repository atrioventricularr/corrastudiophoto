#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/booth/BoothCustomerScreen.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/booth/BoothCustomerScreen.tsx")
text = path.read_text()

pattern = re.compile(
    r"(const\s*\{\s*\n)([\s\S]*?)(\n\s*\}\s*=\s*useBoothFlow\(\);)",
    re.MULTILINE,
)

match = pattern.search(text)

if not match:
    raise SystemExit("Could not find useBoothFlow destructuring block.")

prefix, body, suffix = match.groups()

seen = set()
deduped_lines = []

for line in body.splitlines():
    stripped = line.strip()

    if not stripped:
        deduped_lines.append(line)
        continue

    # Handles lines like: paymentStatus,
    key = stripped.rstrip(",").split(":")[0].strip()

    if key in seen:
        continue

    seen.add(key)
    deduped_lines.append(line)

new_body = "\n".join(deduped_lines)
text = text[:match.start()] + prefix + new_body + suffix + text[match.end():]

path.write_text(text)
print("Fixed duplicate useBoothFlow vars in", path)
PY

echo ""
echo "Current useBoothFlow block:"
sed -n '/const {/,/} = useBoothFlow()/p' "$FILE"

echo ""
echo "Fix done."
