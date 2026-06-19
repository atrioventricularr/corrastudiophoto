#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Fix 10A1 - Make Admin Sidebar Visible"
echo "========================================"

SIDEBAR="apps/booth-ui/src/components/admin/AdminSidebar.tsx"
ADMIN="apps/booth-ui/src/components/AdminPanel.tsx"

[ -f "$SIDEBAR" ] || {
  echo "ERROR: AdminSidebar.tsx not found. Run 10A1 first."
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

text = text.replace(
    'className="sticky top-4 hidden h-[calc(100vh-2rem)] w-72 shrink-0 rounded-[2rem] border border-slate-200 bg-white p-4 shadow-sm xl:block"',
    'className="sticky top-4 hidden h-[calc(100vh-2rem)] w-72 shrink-0 rounded-[2rem] border border-slate-200 bg-white p-4 shadow-sm lg:block"'
)

text = text.replace(
    'className="mb-4 flex gap-2 overflow-x-auto rounded-3xl border border-slate-200 bg-white p-2 xl:hidden"',
    'className="mb-4 flex gap-2 overflow-x-auto rounded-3xl border border-slate-200 bg-white p-2 lg:hidden"'
)

sidebar.write_text(text)
print("PATCH:", sidebar)

admin = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = admin.read_text()

# Kalau sidebar sudah ke-render tapi posisinya cuma numpuk, minimal kasih wrapper flex
# dengan cara aman: tambahkan class flex kalau root punya className.
if "admin-sidebar-shell" in text and "lg:flex" not in text:
    text = text.replace(
        'className="admin-sidebar-shell ',
        'className="admin-sidebar-shell lg:flex lg:gap-6 ',
        1
    )

admin.write_text(text)
print("PATCH:", admin)
PY

echo ""
echo "Check sidebar classes:"
grep -n "lg:block\\|lg:hidden\\|admin-sidebar-shell" "$SIDEBAR" "$ADMIN" || true

echo ""
echo "Done."
