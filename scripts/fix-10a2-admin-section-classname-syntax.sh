#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/AdminPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: AdminPanel.tsx not found"
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

# Fix accidental escaped quotes inside JSX template expressions:
# ? \'block\' : \'hidden\'  ->  ? 'block' : 'hidden'
text = text.replace("\\'block\\'", "'block'")
text = text.replace("\\'hidden\\'", "'hidden'")

# Make sure React useState import exists cleanly.
if "useState" in text and "import React, { useState } from 'react';" not in text:
    text = text.replace("import React from 'react';", "import React, { useState } from 'react';")

path.write_text(text)
print("PATCHED:", path)
PY

echo ""
echo "Relevant className lines:"
grep -n "activeSection ===" "$FILE" || true

echo ""
echo "Now run:"
echo "pnpm --filter @corra/booth-ui typecheck"
