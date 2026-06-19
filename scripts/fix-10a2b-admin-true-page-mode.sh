#!/usr/bin/env bash
set -euo pipefail

ADMIN="apps/booth-ui/src/components/AdminPanel.tsx"
SIDEBAR="apps/booth-ui/src/components/admin/AdminSidebar.tsx"

[ -f "$ADMIN" ] || {
  echo "ERROR: AdminPanel.tsx not found"
  exit 1
}

[ -f "$SIDEBAR" ] || {
  echo "ERROR: AdminSidebar.tsx not found"
  exit 1
}

echo "========================================"
echo " Fix 10A2B - True Admin Page Mode"
echo "========================================"

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
  { id: 'hardware', label: 'Hardware', description: 'Camera, printer, kiosk', emoji: '📷' },
  { id: 'billing', label: 'Billing', description: 'Payment & transactions', emoji: '💳' },
  { id: 'layout', label: 'Layout', description: 'Paper, slots, print area', emoji: '📐' },
  { id: 'template', label: 'Template', description: 'Frame & design assets', emoji: '🖼️' },
  { id: 'branding', label: 'Branding', description: 'Theme, background, logo', emoji: '✨' },
  { id: 'sessions', label: 'Sessions', description: 'Monitor, reports, audit', emoji: '📊' },
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
          Pilih halaman admin.
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
              isActive ? 'bg-slate-950 text-white' : 'bg-slate-50 text-slate-700'
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

# 1. Import useState.
text = text.replace(
    "import React from 'react';",
    "import React, { useState } from 'react';",
)

text = re.sub(
    r"import React, \{([^}]*)\} from 'react';",
    lambda m: "import React, {" + (
        m.group(1) if "useState" in m.group(1) else m.group(1).strip() + ", useState"
    ) + "} from 'react';",
    text,
    count=1,
)

# 2. Import AdminSectionId.
text = text.replace(
    "import { AdminMobileSectionNav, AdminSidebar } from './admin/AdminSidebar';",
    "import { AdminMobileSectionNav, AdminSidebar, type AdminSectionId } from './admin/AdminSidebar';",
)

# 3. Remove old bad section wrappers around known components.
known_components = [
    "CameraSetupPanel",
    "PaymentSettingsPanel",
    "PaymentTransactionsPanel",
    "BrandAppearancePanel",
    "SessionLifecyclePanel",
]

for component in known_components:
    text = re.sub(
        rf"<section[^>]*>\s*<{component}\s*/>\s*</section>",
        f"<{component} />",
        text,
        flags=re.DOTALL,
    )

# 4. Remove old Layout/Template placeholder sections entirely.
text = re.sub(
    r"\s*<section id=\"admin-section-layout\"[\s\S]*?</section>\s*",
    "\n",
    text,
)
text = re.sub(
    r"\s*<section id=\"admin-section-template\"[\s\S]*?</section>\s*",
    "\n",
    text,
)

# 5. Add AdminPage helper once.
if "function AdminPage(" not in text:
    helper = """
function AdminPage({
  activeSection,
  section,
  children,
}: {
  activeSection: AdminSectionId;
  section: AdminSectionId;
  children: React.ReactNode;
}) {
  if (activeSection !== section) {
    return null;
  }

  return <div className="space-y-6">{children}</div>;
}

"""
    # place before export default function AdminPanel
    marker = "export default function AdminPanel"
    if marker not in text:
        raise SystemExit("Could not find export default function AdminPanel.")
    text = text.replace(marker, helper + marker, 1)

# 6. Ensure activeSection state inside function.
# Remove misplaced duplicates first.
text = re.sub(
    r"\n\s*const \[activeSection, setActiveSection\] = useState<AdminSectionId>\('hardware'\);\n",
    "\n",
    text,
)

target = "}: AdminPanelProps) {\n"
if target not in text:
    raise SystemExit("Could not find AdminPanelProps function opening.")

text = text.replace(
    target,
    target + "  const [activeSection, setActiveSection] = useState<AdminSectionId>('hardware');\n\n",
    1,
)

# 7. Ensure nav renders with props.
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

# 8. Add sidebar shell offset.
if "admin-sidebar-shell" in text:
    text = text.replace(
        'className="admin-sidebar-shell lg:flex lg:gap-6 ',
        'className="admin-sidebar-shell lg:pl-80 ',
    )
    if "lg:pl-80" not in text:
        text = text.replace(
            'className="admin-sidebar-shell ',
            'className="admin-sidebar-shell lg:pl-80 ',
            1,
        )

# 9. Wrap known standalone components into true pages, only if not already wrapped.
def wrap_component(component: str, section: str, src: str) -> str:
    if f"<AdminPage activeSection={{activeSection}} section=\"{section}\">\\n        <{component} />" in src:
        return src

    # replace standalone component occurrence
    return src.replace(
        f"<{component} />",
        f"<AdminPage activeSection={{activeSection}} section=\"{section}\">\n          <{component} />\n        </AdminPage>",
        1,
    )

text = wrap_component("CameraSetupPanel", "hardware", text)
text = wrap_component("BrandAppearancePanel", "branding", text)
text = wrap_component("SessionLifecyclePanel", "sessions", text)

# Billing punya dua panel, biar keduanya muncul di Billing.
if "<PaymentSettingsPanel />" in text:
    text = text.replace(
        "<PaymentSettingsPanel />",
        "<AdminPage activeSection={activeSection} section=\"billing\">\n          <PaymentSettingsPanel />\n          {typeof PaymentTransactionsPanel !== 'undefined' && <PaymentTransactionsPanel />}\n        </AdminPage>",
        1,
    )

# Kalau PaymentTransactionsPanel standalone masih ada, hapus supaya tidak muncul dobel / di semua page.
text = re.sub(
    r"\s*<PaymentTransactionsPanel\s*/>\s*",
    "\n",
    text,
    count=1,
)

# 10. Add Layout + Template pages after mobile nav/sidebar block or before branding/session if possible.
if "Layout Builder" not in text:
    layout_page = """
        <AdminPage activeSection={activeSection} section="layout">
          <section className="rounded-[2rem] border border-dashed border-slate-300 bg-white p-5">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Layout
            </p>
            <h3 className="mt-1 text-2xl font-black text-slate-950">
              Layout Builder
            </h3>
            <p className="mt-1 text-sm font-semibold text-slate-500">
              Nanti di sini: paper size, canvas, photo slots, print margin, printer profile, dan custom layout.
            </p>
          </section>
        </AdminPage>

        <AdminPage activeSection={activeSection} section="template">
          <section className="rounded-[2rem] border border-dashed border-slate-300 bg-white p-5">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Template
            </p>
            <h3 className="mt-1 text-2xl font-black text-slate-950">
              Template Manager
            </h3>
            <p className="mt-1 text-sm font-semibold text-slate-500">
              Nanti di sini: upload frame PNG, assign layout, paper size, printer profile, dan preview print.
            </p>
          </section>
        </AdminPage>

"""
    # insert before Branding page if exists, else before Sessions, else near end
    marker = '<AdminPage activeSection={activeSection} section="branding">'
    if marker in text:
        text = text.replace(marker, layout_page + marker, 1)
    else:
        marker = '<AdminPage activeSection={activeSection} section="sessions">'
        if marker in text:
            text = text.replace(marker, layout_page + marker, 1)
        else:
            last_div = text.rfind("</div>")
            if last_div != -1:
                text = text[:last_div] + layout_page + text[last_div:]

# 11. Delete any leftover admin-section ids so old scroll-anchor system is gone.
text = re.sub(r'\s*id="admin-section-[^"]+"', "", text)
text = text.replace("scroll-mt-6", "")

path.write_text(text)
print("PATCHED:", path)
PY

echo ""
echo "Check no scroll/anchor leftovers:"
grep -n "scrollIntoView\\|admin-section-\\|scroll-mt" "$ADMIN" "$SIDEBAR" || true

echo ""
echo "Check page mode lines:"
grep -n "AdminPage\\|activeSection\\|PaymentSettingsPanel\\|PaymentTransactionsPanel\\|Layout Builder\\|Template Manager" "$ADMIN" | head -80 || true
