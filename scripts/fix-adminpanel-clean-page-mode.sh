#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/AdminPanel.tsx"
BACKUP="apps/booth-ui/src/components/AdminPanel.legacy.backup.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: AdminPanel.tsx not found"
  exit 1
}

cp "$FILE" "$BACKUP"

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

start = text.find("export default function AdminPanel")
if start == -1:
    raise SystemExit("Could not find export default function AdminPanel")

prefix = text[:start]

def ensure_import(src: str, import_line: str, token: str) -> str:
    if token in src:
        return src

    lines = src.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
      if line.startswith("import "):
        insert_at = index + 1

    lines.insert(insert_at, import_line)
    return "\n".join(lines) + "\n"

prefix = prefix.replace(
    "import React from 'react';",
    "import React, { useState } from 'react';",
)

prefix = re.sub(
    r"import React, \{([^}]*)\} from 'react';",
    lambda m: "import React, {" + (
        m.group(1) if "useState" in m.group(1) else m.group(1).strip() + ", useState"
    ) + "} from 'react';",
    prefix,
    count=1,
)

prefix = ensure_import(
    prefix,
    "import { AdminMobileSectionNav, AdminSidebar, type AdminSectionId } from './admin/AdminSidebar';",
    "AdminSidebar",
)
prefix = ensure_import(
    prefix,
    "import { CameraSetupPanel } from './camera';",
    "CameraSetupPanel",
)
prefix = ensure_import(
    prefix,
    "import { PaymentSettingsPanel } from './admin/PaymentSettingsPanel';",
    "PaymentSettingsPanel",
)
prefix = ensure_import(
    prefix,
    "import { PaymentTransactionsPanel } from './admin/PaymentTransactionsPanel';",
    "PaymentTransactionsPanel",
)
prefix = ensure_import(
    prefix,
    "import { BrandAppearancePanel } from './admin/BrandAppearancePanel';",
    "BrandAppearancePanel",
)
prefix = ensure_import(
    prefix,
    "import { AdminCredentialPanel } from './admin/AdminCredentialPanel';",
    "AdminCredentialPanel",
)
prefix = ensure_import(
    prefix,
    "import { SessionLifecyclePanel } from './admin/SessionLifecyclePanel';",
    "SessionLifecyclePanel",
)

# Remove old AdminPage helper if present in prefix, then add clean helper.
prefix = re.sub(
    r"\nfunction AdminPage\([\s\S]*?\n}\n\n",
    "\n",
    prefix,
)

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

new_component = """export default function AdminPanel({
  settings,
  onUpdateSettings,
  templates,
  onAddTemplate,
  onRemoveTemplate,
  onClose,
  lang,
}: AdminPanelProps) {
  const [activeSection, setActiveSection] =
    useState<AdminSectionId>('hardware');

  const pricingIDR =
    typeof settings.pricingIDR === 'number' ? settings.pricingIDR : 0;

  const templateCount = Array.isArray(templates) ? templates.length : 0;

  return (
    <div className="admin-sidebar-shell min-h-screen bg-slate-100 p-4 lg:pl-80">
      <AdminSidebar
        activeSection={activeSection}
        onSectionChange={setActiveSection}
      />

      <main className="mx-auto max-w-7xl">
        <AdminMobileSectionNav
          activeSection={activeSection}
          onSectionChange={setActiveSection}
        />

        <header className="mb-6 rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.25em] text-slate-400">
                Corra Admin
              </p>
              <h1 className="mt-1 text-3xl font-black text-slate-950">
                {activeSection.charAt(0).toUpperCase() + activeSection.slice(1)}
              </h1>
              <p className="mt-1 text-sm font-semibold text-slate-500">
                Current language: {lang}
              </p>
            </div>

            <button
              type="button"
              onClick={onClose}
              className="rounded-2xl border border-slate-200 bg-slate-50 px-5 py-3 text-sm font-black text-slate-700"
            >
              Close Admin
            </button>
          </div>
        </header>

        <AdminPage activeSection={activeSection} section="hardware">
          <CameraSetupPanel />

          <section className="rounded-[2rem] border border-dashed border-slate-300 bg-white p-5">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Printer
            </p>
            <h3 className="mt-1 text-2xl font-black text-slate-950">
              Printer Profile
            </h3>
            <p className="mt-1 text-sm font-semibold text-slate-500">
              Next: DNP, printer rumahan, margin, offset, scale correction, dan borderless mode.
            </p>
          </section>
        </AdminPage>

        <AdminPage activeSection={activeSection} section="billing">
          <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Base Pricing
            </p>
            <h3 className="mt-1 text-2xl font-black text-slate-950">
              Session Price
            </h3>

            <label className="mt-4 block">
              <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                Base price per session
              </span>
              <input
                type="number"
                value={pricingIDR}
                onChange={(event) =>
                  onUpdateSettings({
                    ...settings,
                    pricingIDR: Number(event.target.value || 0),
                  })
                }
                className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
              />
            </label>
          </section>

          <PaymentSettingsPanel />
          <PaymentTransactionsPanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="layout">
          <section className="rounded-[2rem] border border-dashed border-slate-300 bg-white p-5">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Layout
            </p>
            <h3 className="mt-1 text-2xl font-black text-slate-950">
              Layout Builder
            </h3>
            <p className="mt-1 text-sm font-semibold text-slate-500">
              Next: paper size, canvas size, photo slots, print area, guide overlay, dan printer profile.
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
              Next: upload frame PNG, assign layout, paper size, printer profile, dan preview print.
            </p>

            <div className="mt-4 rounded-2xl bg-slate-50 p-4">
              <p className="text-sm font-black text-slate-700">
                Current templates: {templateCount}
              </p>
              <p className="mt-1 text-xs font-semibold text-slate-400">
                Legacy custom frame uploader disimpan dulu di backup file. Nanti kita ganti dengan Template Manager baru.
              </p>
            </div>

            <button
              type="button"
              onClick={() => {
                const id = `template-${Date.now()}`;
                onAddTemplate({
                  id,
                  name: `Template ${templateCount + 1}`,
                } as FrameTemplate);
              }}
              className="mt-4 rounded-2xl bg-slate-950 px-5 py-3 text-sm font-black text-white"
            >
              Add Placeholder Template
            </button>

            {templateCount > 0 && (
              <div className="mt-4 space-y-2">
                {templates.map((template) => (
                  <div
                    key={template.id}
                    className="flex items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3"
                  >
                    <div>
                      <p className="text-sm font-black text-slate-800">
                        {template.name || template.id}
                      </p>
                      <p className="font-mono text-xs font-semibold text-slate-400">
                        {template.id}
                      </p>
                    </div>

                    <button
                      type="button"
                      onClick={() => onRemoveTemplate(template.id)}
                      className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-xs font-black text-red-700"
                    >
                      Remove
                    </button>
                  </div>
                ))}
              </div>
            )}
          </section>
        </AdminPage>

        <AdminPage activeSection={activeSection} section="branding">
          <BrandAppearancePanel />
          <AdminCredentialPanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="sessions">
          <SessionLifecyclePanel />
        </AdminPage>
      </main>
    </div>
  );
}
"""

path.write_text(prefix + helper + new_component)
print("REWROTE:", path)
print("BACKUP:", "apps/booth-ui/src/components/AdminPanel.legacy.backup.tsx")
PY

echo ""
echo "Check no legacy text:"
grep -n "PRICING & PAYMENT SETUP\\|VOUCHERS & SECURITY\\|ADD CUSTOM PHOTO FRAMES\\|scrollIntoView\\|admin-section-" "$FILE" || true

echo ""
echo "Check page mode:"
grep -n "AdminPage activeSection\\|section=\"hardware\"\\|section=\"billing\"\\|section=\"layout\"\\|section=\"template\"\\|section=\"branding\"\\|section=\"sessions\"" "$FILE" || true
