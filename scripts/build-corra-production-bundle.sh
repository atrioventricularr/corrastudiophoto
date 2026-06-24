#!/usr/bin/env bash
set -euo pipefail

BUILD_ID="$(date +%Y%m%d%H%M%S)"
VERSION="${CORRA_APP_VERSION:-1.0.0}"
OUT_DIR="release/corra-booth-production-${VERSION}-${BUILD_ID}"

echo "Building Corra production bundle: $OUT_DIR"

pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false
pnpm --filter @corra/booth-ui build

mkdir -p "$OUT_DIR/bundle/booth-ui-dist"
mkdir -p "$OUT_DIR/bundle/apps/desktop-electron"
mkdir -p "$OUT_DIR/bundle/docs"

cp -R apps/booth-ui/dist/. "$OUT_DIR/bundle/booth-ui-dist/"
cp -R apps/desktop-electron/. "$OUT_DIR/bundle/apps/desktop-electron/"
cp docs/phase-10-production-hardening-checklist.md "$OUT_DIR/bundle/docs/" 2>/dev/null || true

cat > "$OUT_DIR/bundle/release-manifest.json" <<JSON
{
  "appName": "Corra Booth",
  "version": "$VERSION",
  "channel": "production",
  "buildId": "$BUILD_ID",
  "builtAt": "$(date -Iseconds)",
  "commit": "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
}
JSON

cat > "$OUT_DIR/README.txt" <<TXT
Corra Booth Production Bundle
Version: $VERSION
Build: $BUILD_ID

Run using Electron from bundle/apps/desktop-electron.
Windows installer/signing is still a separate production step.
TXT

echo "Production bundle generated: $OUT_DIR"
