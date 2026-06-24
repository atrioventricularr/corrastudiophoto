#!/usr/bin/env bash
set -euo pipefail

LATEST_RELEASE="$(ls -td release/corra-booth-* 2>/dev/null | head -1)"

if [ -z "$LATEST_RELEASE" ]; then
  echo "No release folder found."
  exit 1
fi

SOURCE_DIR="apps/desktop-electron"

write_electron_entry() {
  local target="$1"
  mkdir -p "$target"

  # Copy bridge files if available.
  for file in \
    corra-disk-persistence.cjs \
    corra-disk-preload.cjs \
    corra-hardware-diagnostics.cjs \
    corra-hardware-preload.cjs \
    package.json
  do
    if [ -f "$SOURCE_DIR/$file" ]; then
      cp "$SOURCE_DIR/$file" "$target/$file"
    fi
  done

  cat > "$target/main.cjs" <<'CJS'
const path = require('node:path');
const fs = require('node:fs');
const { app, BrowserWindow } = require('electron');

try { require('./corra-disk-persistence.cjs'); } catch (error) {
  console.warn('[Corra] disk bridge not loaded:', error.message);
}

try { require('./corra-hardware-diagnostics.cjs'); } catch (error) {
  console.warn('[Corra] hardware bridge not loaded:', error.message);
}

function findBoothIndex() {
  const candidates = [
    path.join(__dirname, '..', '..', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, '..', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, '..', '..', 'bundle', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, '..', 'bundle', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, 'booth-ui-dist', 'index.html'),
  ];

  const found = candidates.find((candidate) => fs.existsSync(candidate));

  if (!found) {
    throw new Error(`Booth UI index.html not found. Tried: ${candidates.join(', ')}`);
  }

  return found;
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

  const indexPath = findBoothIndex();
  win.loadFile(indexPath, {
    query: {
      mode: 'booth',
      dev: process.env.CORRA_DEV === '1' ? '1' : '0',
      kiosk: process.env.CORRA_KIOSK === '1' ? '1' : '0',
    },
  });

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

  cat > "$target/preload.cjs" <<'CJS'
try { require('./corra-disk-preload.cjs'); } catch (error) {
  console.warn('[Corra] disk preload not loaded:', error.message);
}

try { require('./corra-hardware-preload.cjs'); } catch (error) {
  console.warn('[Corra] hardware preload not loaded:', error.message);
}
CJS

  cat > "$target/index.cjs" <<'CJS'
require('./main.cjs');
CJS
}

write_electron_entry "$LATEST_RELEASE/bundle/apps/desktop-electron"
write_electron_entry "$LATEST_RELEASE/apps/desktop-electron"
write_electron_entry "$LATEST_RELEASE/desktop-electron"
write_electron_entry "$LATEST_RELEASE/electron"

cat > scripts/check-corra-release-candidate.sh <<'CHECK'
#!/usr/bin/env bash
set -u

LATEST_RELEASE="$(ls -td release/corra-booth-* 2>/dev/null | head -1)"
FAILURES=0

echo "Corra Release Candidate Check"
echo "============================="

if [ -z "$LATEST_RELEASE" ]; then
  echo "❌ release folder"
  exit 1
fi

has_file() {
  local label="$1"
  shift

  for file in "$@"; do
    if [ -f "$file" ]; then
      echo "✅ $label"
      return 0
    fi
  done

  echo "❌ $label"
  FAILURES=$((FAILURES + 1))
  return 0
}

has_dir() {
  local label="$1"
  shift

  for dir in "$@"; do
    if [ -d "$dir" ]; then
      echo "✅ $label"
      return 0
    fi
  done

  echo "❌ $label"
  FAILURES=$((FAILURES + 1))
  return 0
}

has_file "booth package/manifest" \
  "$LATEST_RELEASE/bundle/release-manifest.json" \
  "$LATEST_RELEASE/release-manifest.json" \
  "$LATEST_RELEASE/apps/booth-ui/package.json" \
  "$LATEST_RELEASE/booth-ui/package.json"

has_file "booth dist" \
  "$LATEST_RELEASE/bundle/booth-ui-dist/index.html" \
  "$LATEST_RELEASE/booth-ui-dist/index.html" \
  "$LATEST_RELEASE/apps/booth-ui/dist/index.html" \
  "$LATEST_RELEASE/booth-ui/dist/index.html" \
  "$LATEST_RELEASE/dist/index.html"

has_dir "desktop electron" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron" \
  "$LATEST_RELEASE/apps/desktop-electron" \
  "$LATEST_RELEASE/desktop-electron" \
  "$LATEST_RELEASE/electron"

has_file "electron main" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/desktop-electron/main.cjs" \
  "$LATEST_RELEASE/desktop-electron/index.cjs" \
  "$LATEST_RELEASE/electron/main.cjs" \
  "$LATEST_RELEASE/electron/index.cjs"

has_file "electron preload" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/desktop-electron/preload.cjs" \
  "$LATEST_RELEASE/electron/preload.cjs"

has_file "disk bridge" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/desktop-electron/corra-disk-persistence.cjs" \
  "$LATEST_RELEASE/electron/corra-disk-persistence.cjs"

has_file "hardware bridge" \
  "$LATEST_RELEASE/bundle/apps/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/apps/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/desktop-electron/corra-hardware-diagnostics.cjs" \
  "$LATEST_RELEASE/electron/corra-hardware-diagnostics.cjs"

has_file "9G docs" \
  "$LATEST_RELEASE/bundle/docs/phase-9g-packaging-release-checklist.md" \
  "$LATEST_RELEASE/docs/phase-9g-packaging-release-checklist.md" \
  "docs/phase-9g-packaging-release-checklist.md"

echo ""
echo "Latest release:"
echo "$LATEST_RELEASE"

echo ""
echo "Important files:"
find "$LATEST_RELEASE" -maxdepth 5 -type f | sort | grep -E "release-manifest.json|index.html|main.cjs|index.cjs|preload.cjs|corra-" || true

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "✅ Release candidate structure looks good."
else
  echo "❌ Release candidate has $FAILURES issue(s)."
  exit 1
fi
CHECK

chmod +x scripts/check-corra-release-candidate.sh

echo "Patched latest release bundle entries and checker."
echo "Latest release: $LATEST_RELEASE"
