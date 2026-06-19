#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/AdminPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

start = text.find('<AdminPage activeSection={activeSection} section="branding">')
if start == -1:
    raise SystemExit("Could not find branding AdminPage start.")

end_marker = '<AdminPage activeSection={activeSection} section="hardware">'
hardware_start = text.find(end_marker, start)
if hardware_start == -1:
    raise SystemExit("Could not find hardware AdminPage start after branding.")

# Find the end of the hardware AdminPage.
hardware_end = text.find('</AdminPage>', hardware_start)
if hardware_end == -1:
    raise SystemExit("Could not find hardware AdminPage closing tag.")

hardware_end = hardware_end + len('</AdminPage>')

# Remove broken extra closing divs immediately after hardware page.
tail = text[hardware_end:]
while tail.startswith('\n</div>') or tail.startswith('\n  </div>') or tail.startswith('\n          </div>') or tail.startswith('\n        </div>'):
    if tail.startswith('\n</div>'):
        tail = tail[len('\n</div>'):]
    elif tail.startswith('\n  </div>'):
        tail = tail[len('\n  </div>'):]
    elif tail.startswith('\n          </div>'):
        tail = tail[len('\n          </div>'):]
    elif tail.startswith('\n        </div>'):
        tail = tail[len('\n        </div>'):]

clean_block = '''<AdminPage activeSection={activeSection} section="branding">
          <BrandAppearancePanel />

          <div className="mt-6">
            <AdminCredentialPanel />
          </div>
        </AdminPage>

        <AdminPage activeSection={activeSection} section="billing">
          <PaymentSettingsPanel />

          <div className="mt-6">
            <PaymentTransactionsPanel />
          </div>
        </AdminPage>

        <AdminPage activeSection={activeSection} section="sessions">
          <SessionLifecyclePanel />
        </AdminPage>

        <AdminPage activeSection={activeSection} section="hardware">
          <CameraSetupPanel />
        </AdminPage>'''

text = text[:start] + clean_block + tail

# Bersihin sisa broken conditional kalau masih ada.
text = text.replace("{typeof PaymentTransactionsPanel !== 'undefined' &&", "")
text = text.replace("{typeof PaymentTransactionsPanel !== 'undefined' &&\n", "")

path.write_text(text)
print("PATCHED:", path)
PY

echo ""
echo "Check lines 180-225:"
nl -ba "$FILE" | sed -n '180,225p'
