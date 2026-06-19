#!/usr/bin/env bash
set -euo pipefail

ADMIN="apps/booth-ui/src/components/AdminPanel.tsx"

[ -f "$ADMIN" ] || {
  echo "ERROR: AdminPanel.tsx not found"
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

# 1. Ensure PrinterProfilePanel import
if "PrinterProfilePanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1

    lines.insert(
        insert_at,
        "import { PrinterProfilePanel } from './admin/PrinterProfilePanel';",
    )
    text = "\n".join(lines) + "\n"

# 2. Force Hardware page to include CameraSetupPanel + PrinterProfilePanel
hardware_pattern = r'''<AdminPage activeSection=\{activeSection\} section="hardware">[\s\S]*?</AdminPage>'''

hardware_block = '''<AdminPage activeSection={activeSection} section="hardware">
          <CameraSetupPanel />
          <PrinterProfilePanel />
        </AdminPage>'''

text = re.sub(hardware_pattern, hardware_block, text, count=1)

# 3. Make admin shell not scroll whole web page
text = re.sub(
    r'className="admin-sidebar-shell[^"]*"',
    'className="admin-sidebar-shell h-screen overflow-hidden bg-slate-100 p-4 lg:pl-80"',
    text,
    count=1,
)

# 4. Make right content scroll internally
text = re.sub(
    r'<main className="mx-auto max-w-7xl">',
    '<main className="mx-auto h-[calc(100vh-2rem)] max-w-7xl overflow-y-auto pr-2 pb-10">',
    text,
    count=1,
)

path.write_text(text)
print("PATCHED:", path)
PY

echo ""
echo "Check:"
grep -n "PrinterProfilePanel\\|h-screen overflow-hidden\\|overflow-y-auto\\|section=\"hardware\"" "$ADMIN" || true
