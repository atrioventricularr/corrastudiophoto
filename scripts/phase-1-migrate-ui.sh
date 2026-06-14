#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 1 UI Migration"
echo "========================================"

APP_DIR="apps/booth-ui"
ZIP_PATH="${1:-}"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

create_dir() {
  mkdir -p "$1"
  touch "$1/.gitkeep"
}

write_file() {
  local file_path="$1"
  local content="$2"

  mkdir -p "$(dirname "$file_path")"
  printf "%s\n" "$content" > "$file_path"
  echo "WRITE file: $file_path"
}

write_if_missing() {
  local file_path="$1"
  local content="$2"

  mkdir -p "$(dirname "$file_path")"

  if [ -f "$file_path" ]; then
    echo "SKIP existing file: $file_path"
  else
    printf "%s\n" "$content" > "$file_path"
    echo "CREATE file: $file_path"
  fi
}

echo ""
echo "Checking repository structure..."

[ -f "package.json" ] || fail "Root package.json not found. Run Phase 0 first."
[ -f "pnpm-workspace.yaml" ] || fail "pnpm-workspace.yaml not found. Run Phase 0 first."
[ -d "$APP_DIR" ] || fail "$APP_DIR not found. Run Phase 0 first."

echo "Repository structure OK."

echo ""
echo "Resolving UI ZIP file..."

if [ -z "$ZIP_PATH" ]; then
  ZIP_PATH="$(find . -maxdepth 4 -type f \( -iname "*photobooth*ui*.zip" -o -iname "*booth*ui*.zip" -o -iname "*.zip" \) | sort | head -n 1 || true)"
fi

[ -n "$ZIP_PATH" ] || fail "No ZIP file found. Put your UI ZIP in repo root or run: ./scripts/phase-1-migrate-ui.sh path/to/ui.zip"
[ -f "$ZIP_PATH" ] || fail "ZIP file not found at: $ZIP_PATH"

echo "Using ZIP: $ZIP_PATH"

if ! command -v unzip >/dev/null 2>&1; then
  fail "unzip is not installed in this Codespace."
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo ""
echo "Extracting ZIP..."
unzip -q "$ZIP_PATH" -d "$TMP_DIR"

echo ""
echo "Validating extracted UI..."

[ -f "$TMP_DIR/package.json" ] || fail "Extracted ZIP does not contain package.json."
[ -f "$TMP_DIR/index.html" ] || fail "Extracted ZIP does not contain index.html."
[ -f "$TMP_DIR/vite.config.ts" ] || fail "Extracted ZIP does not contain vite.config.ts."
[ -d "$TMP_DIR/src" ] || fail "Extracted ZIP does not contain src folder."
[ -f "$TMP_DIR/src/App.tsx" ] || fail "Extracted ZIP does not contain src/App.tsx."
[ -f "$TMP_DIR/src/main.tsx" ] || fail "Extracted ZIP does not contain src/main.tsx."
[ -f "$TMP_DIR/src/index.css" ] || fail "Extracted ZIP does not contain src/index.css."
[ -d "$TMP_DIR/src/components" ] || fail "Extracted ZIP does not contain src/components folder."

echo "Extracted UI is valid."

echo ""
echo "Creating backup of current booth-ui..."

BACKUP_ROOT="$APP_DIR/.phase-backups"
BACKUP_DIR="$BACKUP_ROOT/phase-1-before-ui-migration-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

for item in src index.html vite.config.ts package.json tsconfig.json metadata.json; do
  if [ -e "$APP_DIR/$item" ]; then
    cp -a "$APP_DIR/$item" "$BACKUP_DIR/"
    echo "BACKUP: $APP_DIR/$item"
  fi
done

echo "Backup stored at: $BACKUP_DIR"

echo ""
echo "Replacing booth-ui source with imported UI..."

rm -rf "$APP_DIR/src"
cp -a "$TMP_DIR/src" "$APP_DIR/src"

cp "$TMP_DIR/index.html" "$APP_DIR/index.html"

if [ -f "$TMP_DIR/metadata.json" ]; then
  cp "$TMP_DIR/metadata.json" "$APP_DIR/metadata.json"
fi

echo "UI source copied."

echo ""
echo "Recreating planned architecture folders inside booth-ui..."

create_dir "$APP_DIR/src/app"
create_dir "$APP_DIR/src/assets"
create_dir "$APP_DIR/src/assets/images"
create_dir "$APP_DIR/src/assets/sounds"
create_dir "$APP_DIR/src/assets/placeholders"
create_dir "$APP_DIR/src/components"
create_dir "$APP_DIR/src/components/common"
create_dir "$APP_DIR/src/components/booth"
create_dir "$APP_DIR/src/components/admin"
create_dir "$APP_DIR/src/components/layout"
create_dir "$APP_DIR/src/hooks"
create_dir "$APP_DIR/src/lib"
create_dir "$APP_DIR/src/platform"
create_dir "$APP_DIR/src/screens"
create_dir "$APP_DIR/src/screens/welcome"
create_dir "$APP_DIR/src/screens/payment"
create_dir "$APP_DIR/src/screens/layout-selection"
create_dir "$APP_DIR/src/screens/template-selection"
create_dir "$APP_DIR/src/screens/camera-capture"
create_dir "$APP_DIR/src/screens/processing"
create_dir "$APP_DIR/src/screens/result"
create_dir "$APP_DIR/src/screens/admin"
create_dir "$APP_DIR/src/styles"

echo ""
echo "Writing stable booth-ui package.json..."

write_file "$APP_DIR/package.json" '{
  "name": "@corra/booth-ui",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0 --port 5173",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 0.0.0.0 --port 4173",
    "typecheck": "tsc --noEmit",
    "lint": "tsc --noEmit",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/booth-core": "workspace:*",
    "@corra/image-engine": "workspace:*",
    "@corra/shared": "workspace:*",
    "lucide-react": "^0.546.0",
    "motion": "^12.23.24",
    "react": "^19.0.1",
    "react-dom": "^19.0.1"
  },
  "devDependencies": {
    "@tailwindcss/vite": "^4.1.14",
    "@types/node": "^22.14.0",
    "@vitejs/plugin-react": "^5.0.4",
    "autoprefixer": "^10.4.21",
    "tailwindcss": "^4.1.14",
    "typescript": "~5.8.2",
    "vite": "^6.2.3"
  }
}'

echo ""
echo "Writing stable booth-ui tsconfig.json..."

write_file "$APP_DIR/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2022",
    "experimentalDecorators": true,
    "useDefineForClassFields": false,
    "module": "ESNext",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,
    "moduleResolution": "Bundler",
    "isolatedModules": true,
    "moduleDetection": "force",
    "allowJs": true,
    "jsx": "react-jsx",
    "allowImportingTsExtensions": true,
    "noEmit": true,
    "paths": {
      "@/*": ["./src/*"],
      "@corra/booth-core": ["../../packages/booth-core/src"],
      "@corra/image-engine": ["../../packages/image-engine/src"],
      "@corra/data-access": ["../../packages/data-access/src"],
      "@corra/shared": ["../../packages/shared/src"]
    }
  },
  "include": ["src", "vite.config.ts"]
}'

echo ""
echo "Writing stable booth-ui vite.config.ts..."

write_file "$APP_DIR/vite.config.ts" 'import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import path from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src")
    }
  },
  server: {
    host: "0.0.0.0",
    port: 5173,
    hmr: process.env.DISABLE_HMR !== "true",
    watch: process.env.DISABLE_HMR === "true" ? null : {}
  },
  preview: {
    host: "0.0.0.0",
    port: 4173
  }
});
'

echo ""
echo "Writing UI migration notes..."

write_file "$APP_DIR/MIGRATION_NOTES.md" '# Corra Booth UI Migration Notes

Phase 1 imported the prototype UI as-is into `apps/booth-ui`.

Current imported structure:

- `src/App.tsx`
- `src/main.tsx`
- `src/index.css`
- `src/constants.ts`
- `src/types.ts`
- `src/utils/audio.ts`
- `src/components/*`

Important:

This phase intentionally does not refactor components into `src/screens/*` yet.

Reason:

The first goal is to make the uploaded UI run inside the monorepo without breaking imports.

Next phase should split:

- `src/components/WelcomeScreen.tsx` → `src/screens/welcome/WelcomeScreen.tsx`
- `src/components/PaymentScreen.tsx` → `src/screens/payment/PaymentScreen.tsx`
- `src/components/LayoutSelectionScreen.tsx` → `src/screens/layout-selection/LayoutSelectionScreen.tsx`
- `src/components/TemplateSelectionScreen.tsx` → `src/screens/template-selection/TemplateSelectionScreen.tsx`
- `src/components/CameraCaptureScreen.tsx` → `src/screens/camera-capture/CameraCaptureScreen.tsx`
- `src/components/ProcessingScreen.tsx` → `src/screens/processing/ProcessingScreen.tsx`
- `src/components/ResultScreen.tsx` → `src/screens/result/ResultScreen.tsx`
- `src/components/AdminPanel.tsx` → `src/screens/admin/AdminPanel.tsx`

Do not place Electron, Windows SDK, printer logic, Mayar secrets, or Supabase service-role keys inside this UI app.
'

write_if_missing "docs/ui-migration.md" '# UI Migration

The uploaded prototype UI is migrated into `apps/booth-ui`.

Phase 1 keeps the UI as-is to reduce breakage.

Later phases will move business logic into `packages/booth-core` and image composition into `packages/image-engine`.
'

echo ""
echo "Checking important imported files..."

REQUIRED_FILES=(
  "$APP_DIR/src/App.tsx"
  "$APP_DIR/src/main.tsx"
  "$APP_DIR/src/index.css"
  "$APP_DIR/src/constants.ts"
  "$APP_DIR/src/types.ts"
  "$APP_DIR/src/components/WelcomeScreen.tsx"
  "$APP_DIR/src/components/PaymentScreen.tsx"
  "$APP_DIR/src/components/LayoutSelectionScreen.tsx"
  "$APP_DIR/src/components/TemplateSelectionScreen.tsx"
  "$APP_DIR/src/components/CameraCaptureScreen.tsx"
  "$APP_DIR/src/components/ProcessingScreen.tsx"
  "$APP_DIR/src/components/ResultScreen.tsx"
  "$APP_DIR/src/components/AdminPanel.tsx"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    fail "Missing expected file after migration: $file"
  fi
done

echo "All important UI files exist."

echo ""
echo "Installing dependencies..."
pnpm install

echo ""
echo "Running booth-ui typecheck..."
pnpm --filter @corra/booth-ui typecheck

echo ""
echo "========================================"
echo " Phase 1 completed."
echo "========================================"
echo ""
echo "Run UI:"
echo "  pnpm dev:ui"
echo ""
echo "Recommended git commit:"
echo "  git add ."
echo "  git commit -m \"feat: migrate booth ui prototype\""
echo ""
