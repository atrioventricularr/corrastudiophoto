#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Fix 10A1B - Sidebar Layout No Overlap"
echo "========================================"

SIDEBAR="apps/booth-ui/src/components/admin/AdminSidebar.tsx"
ADMIN="apps/booth-ui/src/components/AdminPanel.tsx"

[ -f "$SIDEBAR" ] || {
  echo "ERROR: AdminSidebar.tsx not found."
  exit 1
}

[ -f "$ADMIN" ] || {
  echo "ERROR: AdminPanel.tsx not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

sidebar = Path("apps/booth-ui/src/components/admin/AdminSidebar.tsx")
text = sidebar.read_text()

# Bikin sidebar fixed di kiri, bukan sticky di flow normal.
old_classes = [
    'className="sticky top-4 hidden h-[calc(100vh-2rem)] w-72 shrink-0 rounded-[2rem] border border-slate-200 bg-white p-4 shadow-sm lg:block"',
    'className="sticky top-4 hidden h-[calc(100vh-2rem)] w-72 shrink-0 rounded-[2rem] border border-slate-200 bg-white p-4 shadow-sm xl:block"',
]

new_class = 'className="fixed left-4 top-4 z-40 hidden h-[calc(100vh-2rem)] w-72 shrink-0 overflow-auto rounded-[2rem] border border-slate-200 bg-white p-4 shadow-xl lg:block"'

for old in old_classes:
    text = text.replace(old, new_class)

sidebar.write_text(text)
print("PATCH:", sidebar)

admin = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = admin.read_text()

# Remove flex wrapper yang bikin panel-panel jadi item horizontal aneh.
text = text.replace(
    'className="admin-sidebar-shell lg:flex lg:gap-6 ',
    'className="admin-sidebar-shell lg:pl-80 ',
)

# Kalau belum ada padding kiri, tambahkan ke root admin shell.
if 'admin-sidebar-shell' in text and 'lg:pl-80' not in text:
    text = text.replace(
        'className="admin-sidebar-shell ',
        'className="admin-sidebar-shell lg:pl-80 ',
        1,
    )

admin.write_text(text)
print("PATCH:", admin)
PY

echo ""
echo "Check:"
grep -n "fixed left-4\\|lg:pl-80\\|AdminSidebar" "$SIDEBAR" "$ADMIN" || true

echo ""
echo "Done."
