#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10A1 - Admin Sidebar Navigation"
echo "========================================"

mkdir -p apps/booth-ui/src/components/admin

cat > apps/booth-ui/src/components/admin/AdminSidebar.tsx <<'TSX'
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
  activeSection?: AdminSectionId;
};

export function AdminSidebar({ activeSection }: AdminSidebarProps) {
  const handleNavigate = (id: AdminSectionId) => {
    const element = document.getElementById(`admin-section-${id}`);

    if (!element) {
      return;
    }

    element.scrollIntoView({
      behavior: 'smooth',
      block: 'start',
    });
  };

  return (
    <aside className="sticky top-4 hidden h-[calc(100vh-2rem)] w-72 shrink-0 rounded-[2rem] border border-slate-200 bg-white p-4 shadow-sm xl:block">
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
              onClick={() => handleNavigate(item.id)}
              className={`w-full rounded-2xl px-4 py-3 text-left transition ${
                isActive
                  ? 'bg-slate-950 text-white'
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

export function AdminMobileSectionNav() {
  return (
    <div className="mb-4 flex gap-2 overflow-x-auto rounded-3xl border border-slate-200 bg-white p-2 xl:hidden">
      {adminSidebarItems.map((item) => (
        <button
          key={item.id}
          type="button"
          onClick={() => {
            document
              .getElementById(`admin-section-${item.id}`)
              ?.scrollIntoView({
                behavior: 'smooth',
                block: 'start',
              });
          }}
          className="shrink-0 rounded-2xl bg-slate-50 px-4 py-3 text-xs font-black text-slate-700"
        >
          <span className="mr-2">{item.emoji}</span>
          {item.label}
        </button>
      ))}
    </div>
  );
}
TSX

FILE="apps/booth-ui/src/components/AdminPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: AdminPanel.tsx not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

# Add import
if "AdminSidebar" not in text:
    lines = text.splitlines()
    insert_at = 0

    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1

    lines.insert(
        insert_at,
        "import { AdminMobileSectionNav, AdminSidebar } from './admin/AdminSidebar';",
    )
    text = "\n".join(lines) + "\n"

# Add marker ids around known panels/components if they exist.
replacements = [
    (
        "<CameraSetupPanel />",
        '<section id="admin-section-hardware" className="scroll-mt-6"><CameraSetupPanel /></section>',
    ),
    (
        "<PaymentSettingsPanel />",
        '<section id="admin-section-billing" className="scroll-mt-6"><PaymentSettingsPanel /></section>',
    ),
    (
        "<PaymentTransactionsPanel />",
        '<section id="admin-section-billing-log" className="scroll-mt-6"><PaymentTransactionsPanel /></section>',
    ),
    (
        "<BrandAppearancePanel />",
        '<section id="admin-section-branding" className="scroll-mt-6"><BrandAppearancePanel /></section>',
    ),
    (
        "<SessionLifecyclePanel />",
        '<section id="admin-section-sessions" className="scroll-mt-6"><SessionLifecyclePanel /></section>',
    ),
]

for old, new in replacements:
    if old in text and new not in text:
        text = text.replace(old, new)

# Add placeholder sections for layout/template if not present.
if 'id="admin-section-layout"' not in text:
    insert_before = '<section id="admin-section-sessions"'
    placeholder = '''
        <section id="admin-section-layout" className="scroll-mt-6 rounded-[2rem] border border-dashed border-slate-300 bg-white p-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Layout
          </p>
          <h3 className="mt-1 text-2xl font-black text-slate-950">
            Layout Builder
          </h3>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Nanti di sini: paper size, canvas, photo slots, printer profile, dan custom layout.
          </p>
        </section>

        <section id="admin-section-template" className="scroll-mt-6 rounded-[2rem] border border-dashed border-slate-300 bg-white p-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Template
          </p>
          <h3 className="mt-1 text-2xl font-black text-slate-950">
            Template Manager
          </h3>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Nanti di sini: upload frame PNG, assign layout, paper size, dan preview print.
          </p>
        </section>

'''
    if insert_before in text:
        text = text.replace(insert_before, placeholder + insert_before, 1)
    else:
        last_div = text.rfind("</div>")
        if last_div != -1:
            text = text[:last_div] + placeholder + text[last_div:]

# Wrap admin content in sidebar shell, best-effort.
# This is intentionally conservative: if wrapper already exists, skip.
if "AdminMobileSectionNav" in text and "admin-sidebar-shell" not in text:
    # Insert mobile nav after first returned container opening if possible.
    # Add sidebar before main content by wrapping the existing top-level content area.
    # If exact structure is unknown, add sidebar at top and mobile nav after it.
    marker = "return ("
    if marker in text:
        # Do not attempt full JSX restructure if risky; instead add visible nav near top.
        # Find first JSX opening after return.
        idx = text.find(marker)
        open_idx = text.find("<", idx)
        close_idx = text.find(">", open_idx)
        if open_idx != -1 and close_idx != -1:
            # Add data marker to existing root className if possible
            root_open = text[open_idx:close_idx+1]
            if "admin-sidebar-shell" not in root_open:
                if "className=" in root_open:
                    new_root_open = root_open.replace(
                        "className=\"",
                        "className=\"admin-sidebar-shell ",
                        1,
                    )
                    text = text[:open_idx] + new_root_open + text[close_idx+1:]
                    close_idx = open_idx + len(new_root_open) - 1

            insertion = "\n      <AdminMobileSectionNav />\n      <AdminSidebar />\n"
            # Add only if not already rendered
            if "<AdminSidebar />" not in text:
                text = text[:close_idx+1] + insertion + text[close_idx+1:]

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "AdminSidebar" "$FILE" || {
  echo "ERROR: AdminSidebar not imported/rendered in AdminPanel."
  exit 1
}

grep -q "admin-section-layout" "$FILE" || {
  echo "ERROR: Layout section placeholder missing."
  exit 1
}

grep -q "admin-section-template" "$FILE" || {
  echo "ERROR: Template section placeholder missing."
  exit 1
}

echo ""
echo "Relevant AdminPanel lines:"
grep -n "AdminSidebar\\|AdminMobileSectionNav\\|admin-section-" "$FILE" || true

echo ""
echo "Phase 10A1 completed."
