#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10A2 - Admin Section Pages"
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

cat > "$SIDEBAR" <<'TSX'
import React from 'react';

export type AdminSectionId =
  | 'hardware'
  | 'billing'
  | 'layout'
  | 'template'
  | 'branding'
  | 'sessions';

type AdminSidebarItem = {
  id: AdminSectionId;
  label: string;
  description: string;
  emoji: string;
};

const adminSidebarItems: AdminSidebarItem[] = [
  {
    id: 'hardware',
    label: 'Hardware',
    description: 'Camera, printer, kiosk',
    emoji: '📷',
  },
  {
    id: 'billing',
    label: 'Billing',
    description: 'Payment & transactions',
    emoji: '💳',
  },
  {
    id: 'layout',
    label: 'Layout',
    description: 'Paper, slots, print area',
    emoji: '📐',
  },
  {
    id: 'template',
    label: 'Template',
    description: 'Frame & design assets',
    emoji: '🖼️',
  },
  {
    id: 'branding',
    label: 'Branding',
    description: 'Theme, background, logo',
    emoji: '✨',
  },
  {
    id: 'sessions',
    label: 'Sessions',
    description: 'Monitor, reports, audit',
    emoji: '📊',
  },
];

type AdminSidebarProps = {
  activeSection: AdminSectionId;
  onSectionChange: (section: AdminSectionId) => void;
};

export function AdminSidebar({
  activeSection,
  onSectionChange,
}: AdminSidebarProps) {
  return (
    <aside className="fixed left-4 top-4 z-40 hidden h-[calc(100vh-2rem)] w-72 shrink-0 overflow-auto rounded-[2rem] border border-slate-200 bg-white p-4 shadow-xl lg:block">
      <div className="rounded-3xl bg-slate-950 p-5 text-white">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-white/40">
          Corra Admin
        </p>
        <h2 className="mt-2 text-2xl font-black">Control Center</h2>
        <p className="mt-2 text-xs font-semibold text-white/50">
          Hardware, payment, layout, template, branding, dan reports.
        </p>
      </div>

      <nav className="mt-4 space-y-2">
        {adminSidebarItems.map((item) => {
          const isActive = activeSection === item.id;

          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onSectionChange(item.id)}
              className={`w-full rounded-2xl px-4 py-3 text-left transition ${
                isActive
                  ? 'bg-slate-950 text-white shadow-md'
                  : 'bg-slate-50 text-slate-700 hover:bg-slate-100'
              }`}
            >
              <div className="flex items-center gap-3">
                <span className="text-xl">{item.emoji}</span>
                <div>
                  <p className="text-sm font-black">{item.label}</p>
                  <p
                    className={`text-[11px] font-semibold ${
                      isActive ? 'text-white/50' : 'text-slate-400'
                    }`}
                  >
                    {item.description}
                  </p>
                </div>
              </div>
            </button>
          );
        })}
      </nav>
    </aside>
  );
}

export function AdminMobileSectionNav({
  activeSection,
  onSectionChange,
}: AdminSidebarProps) {
  return (
    <div className="mb-4 flex gap-2 overflow-x-auto rounded-3xl border border-slate-200 bg-white p-2 lg:hidden">
      {adminSidebarItems.map((item) => {
        const isActive = activeSection === item.id;

        return (
          <button
            key={item.id}
            type="button"
            onClick={() => onSectionChange(item.id)}
            className={`shrink-0 rounded-2xl px-4 py-3 text-xs font-black ${
              isActive
                ? 'bg-slate-950 text-white'
                : 'bg-slate-50 text-slate-700'
            }`}
          >
            <span className="mr-2">{item.emoji}</span>
            {item.label}
          </button>
        );
      })}
    </div>
  );
}
TSX

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

# 1. Import useState kalau belum ada.
if "useState" not in text.split("\n", 5)[0:5]:
    if "import React from 'react';" in text:
        text = text.replace(
            "import React from 'react';",
            "import React, { useState } from 'react';",
            1,
        )
    elif 'import React from "react";' in text:
        text = text.replace(
            'import React from "react";',
            'import React, { useState } from "react";',
            1,
        )
    elif "from 'react'" in text and "useState" not in text:
        text = re.sub(
            r"import\s+\{([^}]*)\}\s+from 'react';",
            lambda m: "import {" + m.group(1).strip() + ", useState } from 'react';",
            text,
            count=1,
        )

# 2. Import type AdminSectionId.
if "type AdminSectionId" not in text:
    text = text.replace(
        "import { AdminMobileSectionNav, AdminSidebar } from './admin/AdminSidebar';",
        "import { AdminMobileSectionNav, AdminSidebar, type AdminSectionId } from './admin/AdminSidebar';",
    )

# 3. Tambah state activeSection setelah function opening.
if "const [activeSection, setActiveSection]" not in text:
    match = re.search(r"(export function AdminPanel[^{]*\{\n|function AdminPanel[^{]*\{\n|const AdminPanel[^=]*=\s*\([^)]*\)\s*=>\s*\{\n)", text)
    if not match:
        raise SystemExit("Could not find AdminPanel function opening.")

    state = "  const [activeSection, setActiveSection] = useState<AdminSectionId>('hardware');\n\n"
    text = text[:match.end()] + state + text[match.end():]

# 4. Patch AdminSidebar render props.
text = text.replace(
    "<AdminMobileSectionNav />",
    "<AdminMobileSectionNav activeSection={activeSection} onSectionChange={setActiveSection} />",
)

text = text.replace(
    "<AdminSidebar />",
    "<AdminSidebar activeSection={activeSection} onSectionChange={setActiveSection} />",
)

# 5. Pastikan root punya padding kiri.
if "admin-sidebar-shell" in text and "lg:pl-80" not in text:
    text = text.replace(
        'className="admin-sidebar-shell ',
        'className="admin-sidebar-shell lg:pl-80 ',
        1,
    )

# 6. Ubah section wrappers jadi tab/page visibility.
section_rules = {
    "hardware": "activeSection === 'hardware'",
    "billing": "activeSection === 'billing'",
    "billing-log": "activeSection === 'billing'",
    "layout": "activeSection === 'layout'",
    "template": "activeSection === 'template'",
    "branding": "activeSection === 'branding'",
    "sessions": "activeSection === 'sessions'",
}

for section, condition in section_rules.items():
    # className normal
    pattern = rf'<section id="admin-section-{section}" className="([^"]*)">'
    replacement = rf'<section id="admin-section-{section}" className={{`$1 ${{{condition} ? \'block\' : \'hidden\'}}`}}>'
    text = re.sub(pattern, replacement, text)

# 7. Kalau section belum ada placeholder, biarkan. 10A1 sudah bikin layout/template.
path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "activeSection" "$ADMIN" || {
  echo "ERROR: activeSection missing in AdminPanel."
  exit 1
}

grep -q "onSectionChange" "$ADMIN" || {
  echo "ERROR: onSectionChange missing in AdminPanel."
  exit 1
}

grep -q "activeSection === 'hardware'" "$ADMIN" || {
  echo "ERROR: hardware section conditional missing."
  exit 1
}

echo ""
echo "Relevant lines:"
grep -n "activeSection\\|AdminSidebar\\|AdminMobileSectionNav\\|admin-section-" "$ADMIN" || true

echo ""
echo "Phase 10A2 completed."
