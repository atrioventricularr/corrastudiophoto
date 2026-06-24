#!/usr/bin/env bash
set -euo pipefail

echo "Building Corra Booth Windows installer..."

pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
pnpm --filter @corra/booth-ui build

rm -rf apps/desktop-electron/booth-ui-dist
mkdir -p apps/desktop-electron/booth-ui-dist
cp -R apps/booth-ui/dist/. apps/desktop-electron/booth-ui-dist/

if pnpm --dir apps/desktop-electron exec electron-builder --version >/dev/null 2>&1; then
  pnpm --dir apps/desktop-electron exec electron-builder --win --x64
else
  echo "electron-builder not installed in apps/desktop-electron."
  echo "Install it first:"
  echo "  pnpm --dir apps/desktop-electron add -D electron-builder"
  exit 1
fi

echo "Installer output:"
find apps/desktop-electron/dist-installer -maxdepth 2 -type f 2>/dev/null | sort || true
