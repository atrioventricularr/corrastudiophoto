#!/usr/bin/env bash
set -euo pipefail

mkdir -p apps/desktop-electron

cat > apps/desktop-electron/main.cjs <<'CJS'
const path = require('node:path');
const fs = require('node:fs');
const { app, BrowserWindow } = require('electron');

try { require('./corra-disk-persistence.cjs'); } catch (error) {
  console.warn('[Corra] disk IPC not loaded:', error.message);
}

try { require('./corra-hardware-diagnostics.cjs'); } catch (error) {
  console.warn('[Corra] hardware IPC not loaded:', error.message);
}

function findBoothDistIndex() {
  const candidates = [
    path.join(__dirname, '..', 'booth-ui', 'dist', 'index.html'),
    path.join(__dirname, '..', '..', 'apps', 'booth-ui', 'dist', 'index.html'),
    path.join(__dirname, '..', '..', 'bundle', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, '..', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, 'booth-ui-dist', 'index.html'),
  ];

  return candidates.find((candidate) => fs.existsSync(candidate));
}

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 960,
    backgroundColor: '#020617',
    fullscreen: process.env.CORRA_KIOSK === '1',
    kiosk: process.env.CORRA_KIOSK === '1',
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  const devUrl = process.env.CORRA_DEV_URL || 'http://127.0.0.1:5173';
  const distIndex = findBoothDistIndex();

  if (process.env.CORRA_DEV === '1') {
    win.loadURL(`${devUrl}/?mode=booth&dev=1`);
  } else if (distIndex) {
    win.loadFile(distIndex, {
      query: {
        mode: 'booth',
        dev: process.env.CORRA_DEV === '1' ? '1' : '0',
        kiosk: process.env.CORRA_KIOSK === '1' ? '1' : '0',
      },
    });
  } else {
    win.loadURL(`${devUrl}/?mode=booth&dev=1`);
  }

  if (process.env.CORRA_DEVTOOLS === '1') {
    win.webContents.openDevTools({ mode: 'detach' });
  }

  return win;
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
CJS

cat > apps/desktop-electron/preload.cjs <<'CJS'
try { require('./corra-disk-preload.cjs'); } catch (error) {
  console.warn('[Corra] disk preload not loaded:', error.message);
}

try { require('./corra-hardware-preload.cjs'); } catch (error) {
  console.warn('[Corra] hardware preload not loaded:', error.message);
}
CJS

cat > apps/desktop-electron/index.cjs <<'CJS'
require('./main.cjs');
CJS

python - <<'PY'
from pathlib import Path
import json

path = Path("apps/desktop-electron/package.json")
if path.exists():
    data = json.loads(path.read_text())
else:
    data = {"name": "@corra/desktop-electron", "private": True, "version": "0.0.0"}

data["main"] = "main.cjs"
scripts = data.setdefault("scripts", {})
scripts.setdefault("start", "electron .")
scripts.setdefault("dev", "cross-env CORRA_DEV=1 CORRA_DEVTOOLS=1 electron .")

path.write_text(json.dumps(data, indent=2) + "\n")
print("PATCH:", path)
PY

cat > scripts/audit-corra-production.sh <<'SH'
#!/usr/bin/env bash
set -u

FAILURES=0
WARNINGS=0

ok(){ echo "✅ $1"; }
warn(){ echo "⚠️ $1"; WARNINGS=$((WARNINGS + 1)); }
fail(){ echo "❌ $1"; FAILURES=$((FAILURES + 1)); }

has_file(){ [ -f "$1" ] && ok "$2" || fail "$2"; }
has_dir(){ [ -d "$1" ] && ok "$2" || fail "$2"; }

echo "Corra Production Audit"
echo "======================"

has_file "apps/booth-ui/package.json" "booth-ui package"
has_file "apps/desktop-electron/package.json" "desktop-electron package"
has_file "apps/desktop-electron/main.cjs" "electron main"
has_file "apps/desktop-electron/preload.cjs" "electron preload"
has_file "apps/desktop-electron/corra-disk-persistence.cjs" "disk IPC"
has_file "apps/desktop-electron/corra-hardware-diagnostics.cjs" "hardware IPC"
has_dir "supabase/functions" "supabase functions"

SECRET_SCAN="$(grep -R \
  --exclude-dir=node_modules \
  --exclude-dir=dist \
  --exclude-dir=.vite \
  --exclude-dir=release \
  "SUPABASE_SERVICE_ROLE_KEY\|MAYAR_API_KEY" \
  -n apps/booth-ui apps/desktop-electron supabase/functions 2>/dev/null \
  | grep -v "Deno.env" \
  | grep -v "process.env" \
  | grep -v "secrets set" || true)"

if [ -n "$SECRET_SCAN" ]; then
  warn "possible frontend secret references found"
  echo "$SECRET_SCAN"
else
  ok "no obvious frontend service-role/mayar secret literals"
fi

if [ -f "apps/booth-ui/.env.local" ]; then
  grep -q "VITE_SUPABASE_ANON_KEY=" apps/booth-ui/.env.local && ok "VITE_SUPABASE_ANON_KEY present" || warn "VITE_SUPABASE_ANON_KEY missing"
  grep -q "VITE_UPLOAD_BOOTH_ASSET_URL=" apps/booth-ui/.env.local && ok "cloud upload URL present" || warn "cloud upload URL missing"
  grep -q "VITE_CREATE_MAYAR_CHECKOUT_URL=" apps/booth-ui/.env.local && ok "Mayar checkout URL present" || warn "Mayar checkout URL missing"
else
  warn "apps/booth-ui/.env.local missing"
fi

echo ""
echo "Warnings: $WARNINGS"
echo "Failures: $FAILURES"

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
SH

chmod +x scripts/audit-corra-production.sh

echo "Fixed Phase 10 electron main/preload and production audit."
