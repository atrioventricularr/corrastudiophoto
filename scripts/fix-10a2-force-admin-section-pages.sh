#!/usr/bin/env bash
set -euo pipefail

SIDEBAR="apps/booth-ui/src/components/admin/AdminSidebar.tsx"
ADMIN="apps/booth-ui/src/components/AdminPanel.tsx"

cat > "$SIDEBAR" <<'TSX'
import React from 'react';

export type AdminSectionId =
  | 'hardware'
  | 'billing'
  | 'layout'
  | 'template'
  | 'branding'
  | 'sessions';

const items: Array<{
  id: AdminSectionId;
  label: string;
  description: string;
  emoji: string;
}> = [
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

type Props = {
  activeSection: AdminSectionId;
  onSectionChange: (section: AdminSectionId) => void;
};

export function AdminSidebar({ activeSection, onSectionChange }: Props) {
  return (
    <aside className="fixed left-4 top-4 z-40 hidden h-[calc(100vh-2rem)] w-72 overflow-auto rounded-[2rem] border border-slate-200 bg-white p-4 shadow-xl lg:block">
      <div className="rounded-3xl bg-slate-950 p-5 text-white">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-white/40">
          Corra Admin
        </p>
        <h2 className="mt-2 text-2xl font-black">Control Center</h2>
        <p className="mt-2 text-xs font-semibold text-white/50">
          Pilih halaman admin di bawah.
        </p>
      </div>

      <nav className="mt-4 space-y-2">
        {items.map((item) => {
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
                  <p className={`text-[11px] font-semibold ${isActive ? 'text-white/50' : 'text-slate-400'}`}>
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
}: Props) {
  return (
    <div className="mb-4 flex gap-2 overflow-x-auto rounded-3xl border border-slate-200 bg-white p-2 lg:hidden">
      {items.map((item) => {
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

# Ensure imports
text = text.replace(
    "import React from 'react';",
    "import React, { useState } from 'react';",
)

if "type AdminSectionId" not in text:
    text = text.replace(
        "import { AdminMobileSectionNav, AdminSidebar } from './admin/AdminSidebar';",
        "import { AdminMobileSectionNav, AdminSidebar, type AdminSectionId } from './admin/AdminSidebar';",
    )

# Ensure state after function opening
if "const [activeSection, setActiveSection]" not in text:
    target = "}: AdminPanelProps) {\n"
    text = text.replace(
        target,
        target + "  const [activeSection, setActiveSection] = useState<AdminSectionId>('hardware');\n\n",
        1,
    )

# Ensure nav uses state, not old props
text = re.sub(
    r"<AdminMobileSectionNav\s*/>",
    "<AdminMobileSectionNav activeSection={activeSection} onSectionChange={setActiveSection} />",
    text,
)
text = re.sub(
    r"<AdminSidebar\s*/>",
    "<AdminSidebar activeSection={activeSection} onSectionChange={setActiveSection} />",
    text,
)

# Helper to force hide/show section by id.
conditions = {
    "hardware": "activeSection === 'hardware'",
    "billing": "activeSection === 'billing'",
    "billing-log": "activeSection === 'billing'",
    "layout": "activeSection === 'layout'",
    "template": "activeSection === 'template'",
    "branding": "activeSection === 'branding'",
    "sessions": "activeSection === 'sessions'",
}

for section_id, condition in conditions.items():
    # Replace any section opening with that id, regardless existing className style.
    pattern = rf'<section id="admin-section-{section_id}"[^>]*>'
    replacement = (
        f'<section id="admin-section-{section_id}" '
        f'className={{`${{{condition} ? "block" : "hidden"}}`}}>'
    )
    text = re.sub(pattern, replacement, text)

# If sidebar shell exists, ensure content offset, but no flex horizontal weirdness.
text = text.replace(
    'className="admin-sidebar-shell lg:flex lg:gap-6 ',
    'className="admin-sidebar-shell lg:pl-80 ',
)
if 'admin-sidebar-shell' in text and 'lg:pl-80' not in text:
    text = text.replace(
        'className="admin-sidebar-shell ',
        'className="admin-sidebar-shell lg:pl-80 ',
        1,
    )

path.write_text(text)
print("PATCHED:", path)
PY

echo ""
echo "Check no scrollIntoView:"
grep -n "scrollIntoView" "$SIDEBAR" "$ADMIN" || true

echo ""
echo "Check conditional sections:"
grep -n "admin-section-.*activeSection" "$ADMIN" || true
