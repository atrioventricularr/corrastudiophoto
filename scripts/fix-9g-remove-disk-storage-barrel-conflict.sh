#!/usr/bin/env bash
set -euo pipefail

INDEX_FILE="apps/booth-ui/src/booth/index.ts"

cp "$INDEX_FILE" "$INDEX_FILE.bak.$(date +%Y%m%d%H%M%S)"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/index.ts")
lines = path.read_text().splitlines()

remove_patterns = [
    "export * from './booth-disk-storage';",
    'export * from "./booth-disk-storage";',
]

next_lines = []
seen = set()

for line in lines:
    stripped = line.strip()

    if stripped in remove_patterns:
        continue

    if stripped.startswith("export * from "):
        if stripped in seen:
            continue
        seen.add(stripped)

    next_lines.append(line)

path.write_text("\n".join(next_lines) + "\n")
print("Removed booth-disk-storage barrel export conflict.")
PY
