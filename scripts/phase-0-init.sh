#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 0 Init"
echo "========================================"

PROJECT_SLUG="corra-booth"

create_dir() {
  mkdir -p "$1"
  touch "$1/.gitkeep"
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
echo "Checking runtime..."

if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Node.js is not installed."
  exit 1
fi

echo "Node version: $(node -v)"

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm not found. Enabling pnpm via corepack..."
  corepack enable
  corepack prepare pnpm@9.15.4 --activate
fi

echo "pnpm version: $(pnpm -v)"

echo ""
echo "Creating root folders..."

create_dir ".github"
create_dir ".github/workflows"
create_dir ".vscode"
create_dir "scripts"
create_dir "docs"

echo ""
echo "Creating apps folders..."

# Desktop Electron app
create_dir "apps"
create_dir "apps/desktop-electron"
create_dir "apps/desktop-electron/electron"
create_dir "apps/desktop-electron/electron/main"
create_dir "apps/desktop-electron/electron/main/ipc"
create_dir "apps/desktop-electron/electron/main/native"
create_dir "apps/desktop-electron/electron/main/native/windows"
create_dir "apps/desktop-electron/electron/main/native/windows/cameras"
create_dir "apps/desktop-electron/electron/main/native/windows/cameras/canon"
create_dir "apps/desktop-electron/electron/main/native/windows/cameras/sony"
create_dir "apps/desktop-electron/electron/main/native/windows/cameras/webcam"
create_dir "apps/desktop-electron/electron/main/native/windows/printers"
create_dir "apps/desktop-electron/electron/main/native/windows/printers/dnp"
create_dir "apps/desktop-electron/electron/main/native/windows/printers/thermal"
create_dir "apps/desktop-electron/electron/main/native/windows/printers/epson"
create_dir "apps/desktop-electron/electron/main/native/windows/bluetooth"
create_dir "apps/desktop-electron/electron/main/security"
create_dir "apps/desktop-electron/electron/preload"
create_dir "apps/desktop-electron/resources"
create_dir "apps/desktop-electron/resources/default-assets"

# Main booth UI
create_dir "apps/booth-ui"
create_dir "apps/booth-ui/public"
create_dir "apps/booth-ui/src"
create_dir "apps/booth-ui/src/app"
create_dir "apps/booth-ui/src/assets"
create_dir "apps/booth-ui/src/assets/images"
create_dir "apps/booth-ui/src/assets/sounds"
create_dir "apps/booth-ui/src/assets/placeholders"
create_dir "apps/booth-ui/src/components"
create_dir "apps/booth-ui/src/components/common"
create_dir "apps/booth-ui/src/components/booth"
create_dir "apps/booth-ui/src/components/admin"
create_dir "apps/booth-ui/src/components/layout"
create_dir "apps/booth-ui/src/hooks"
create_dir "apps/booth-ui/src/lib"
create_dir "apps/booth-ui/src/platform"
create_dir "apps/booth-ui/src/screens"
create_dir "apps/booth-ui/src/screens/welcome"
create_dir "apps/booth-ui/src/screens/payment"
create_dir "apps/booth-ui/src/screens/layout-selection"
create_dir "apps/booth-ui/src/screens/template-selection"
create_dir "apps/booth-ui/src/screens/camera-capture"
create_dir "apps/booth-ui/src/screens/processing"
create_dir "apps/booth-ui/src/screens/result"
create_dir "apps/booth-ui/src/screens/admin"
create_dir "apps/booth-ui/src/styles"

# Admin web
create_dir "apps/admin-web"
create_dir "apps/admin-web/public"
create_dir "apps/admin-web/src"
create_dir "apps/admin-web/src/app"
create_dir "apps/admin-web/src/components"
create_dir "apps/admin-web/src/features"
create_dir "apps/admin-web/src/features/licenses"
create_dir "apps/admin-web/src/features/transactions"
create_dir "apps/admin-web/src/features/booth-owners"
create_dir "apps/admin-web/src/features/templates"
create_dir "apps/admin-web/src/pages"
create_dir "apps/admin-web/src/services"
create_dir "apps/admin-web/src/styles"

# Download page
create_dir "apps/download-page"
create_dir "apps/download-page/public"
create_dir "apps/download-page/src"
create_dir "apps/download-page/src/app"
create_dir "apps/download-page/src/components"
create_dir "apps/download-page/src/pages"
create_dir "apps/download-page/src/services"
create_dir "apps/download-page/src/styles"

# Landing page
create_dir "apps/landing-page"
create_dir "apps/landing-page/public"
create_dir "apps/landing-page/src"
create_dir "apps/landing-page/src/app"
create_dir "apps/landing-page/src/components"
create_dir "apps/landing-page/src/pages"
create_dir "apps/landing-page/src/sections"
create_dir "apps/landing-page/src/styles"

echo ""
echo "Creating packages folders..."

# Booth core
create_dir "packages"
create_dir "packages/booth-core"
create_dir "packages/booth-core/src"
create_dir "packages/booth-core/src/domain"
create_dir "packages/booth-core/src/use-cases"
create_dir "packages/booth-core/src/ports"
create_dir "packages/booth-core/src/state"

# Image engine
create_dir "packages/image-engine"
create_dir "packages/image-engine/src"
create_dir "packages/image-engine/src/composer"
create_dir "packages/image-engine/src/gif"
create_dir "packages/image-engine/src/qr"
create_dir "packages/image-engine/src/canvas"

# Data access
create_dir "packages/data-access"
create_dir "packages/data-access/src"
create_dir "packages/data-access/src/supabase"
create_dir "packages/data-access/src/local"

# Shared
create_dir "packages/shared"
create_dir "packages/shared/src"
create_dir "packages/shared/src/types"
create_dir "packages/shared/src/constants"
create_dir "packages/shared/src/validators"

# Config
create_dir "packages/config"
create_dir "packages/config/eslint"
create_dir "packages/config/typescript"
create_dir "packages/config/vite"

echo ""
echo "Creating infra folders..."

create_dir "infra"
create_dir "infra/supabase"
create_dir "infra/supabase/migrations"
create_dir "infra/supabase/functions"
create_dir "infra/supabase/functions/mayar-webhook"
create_dir "infra/supabase/functions/verify-license"
create_dir "infra/supabase/functions/create-download-token"
create_dir "infra/supabase/functions/cleanup-expired-assets"
create_dir "infra/netlify"

echo ""
echo "Creating root config files..."

write_if_missing "package.json" '{
  "name": "corra-booth",
  "private": true,
  "version": "0.1.0",
  "description": "Corra Booth - Commercial Windows Desktop Photobooth Software",
  "packageManager": "pnpm@9.15.4",
  "scripts": {
    "dev:ui": "pnpm --filter @corra/booth-ui dev",
    "dev:desktop": "pnpm --filter @corra/desktop-electron dev",
    "dev:admin": "pnpm --filter @corra/admin-web dev",
    "dev:download": "pnpm --filter @corra/download-page dev",
    "dev:landing": "pnpm --filter @corra/landing-page dev",
    "build": "pnpm -r build",
    "build:ui": "pnpm --filter @corra/booth-ui build",
    "build:desktop": "pnpm --filter @corra/desktop-electron build",
    "typecheck": "pnpm -r typecheck",
    "lint": "pnpm -r lint",
    "clean": "pnpm -r clean"
  },
  "devDependencies": {
    "turbo": "^2.3.3",
    "typescript": "^5.7.2"
  }
}'

write_if_missing "pnpm-workspace.yaml" 'packages:
  - "apps/*"
  - "packages/*"'

write_if_missing "turbo.json" '{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", "build/**", "out/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "typecheck": {
      "dependsOn": ["^typecheck"]
    },
    "lint": {
      "dependsOn": ["^lint"]
    },
    "clean": {
      "cache": false
    }
  }
}'

write_if_missing "tsconfig.base.json" '{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "baseUrl": ".",
    "paths": {
      "@corra/booth-core": ["packages/booth-core/src"],
      "@corra/image-engine": ["packages/image-engine/src"],
      "@corra/data-access": ["packages/data-access/src"],
      "@corra/shared": ["packages/shared/src"]
    }
  }
}'

write_if_missing ".gitignore" '# Dependencies
node_modules/
.pnpm-store/

# Build outputs
dist/
build/
out/
release/
.turbo/

# Env
.env
.env.local
.env.*.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json

# Electron
apps/desktop-electron/dist/
apps/desktop-electron/release/

# Supabase
.supabase/

# Local database/cache
*.sqlite
*.sqlite3
*.db

# Temporary media
tmp/
temp/
.local-media/
'

write_if_missing ".env.example" '# App
VITE_APP_NAME="Corra Booth"
VITE_APP_ENV="development"

# Supabase Public Client
VITE_SUPABASE_URL=""
VITE_SUPABASE_ANON_KEY=""

# Supabase Server / Edge Function
SUPABASE_SERVICE_ROLE_KEY=""

# Mayar
MAYAR_API_KEY=""
MAYAR_WEBHOOK_SECRET=""

# Netlify Download Page
VITE_DOWNLOAD_PAGE_BASE_URL="https://your-download-page.netlify.app"

# Electron
ELECTRON_ENABLE_LOGGING=true
'

write_if_missing ".vscode/extensions.json" '{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-typescript-next"
  ]
}'

write_if_missing ".vscode/settings.json" '{
  "editor.formatOnSave": true,
  "typescript.preferences.importModuleSpecifier": "non-relative",
  "files.eol": "\n"
}'

write_if_missing "README.md" '# Corra Booth

Commercial Windows Desktop Photobooth Software.

## Architecture

Corra Booth is structured as a portable web/core application with a Windows Electron adapter.

Main apps:

- `apps/booth-ui` - Main photobooth user interface.
- `apps/desktop-electron` - Windows desktop shell and native hardware bridge.
- `apps/admin-web` - Remote admin dashboard.
- `apps/download-page` - Public photo download page from QR code.
- `apps/landing-page` - Marketing and software download landing page.

Core packages:

- `packages/booth-core` - Business logic.
- `packages/image-engine` - Frame composition, GIF, QR generation.
- `packages/data-access` - Supabase and local persistence.
- `packages/shared` - Shared types, constants, validators.
'

echo ""
echo "Creating app package files..."

write_if_missing "apps/booth-ui/package.json" '{
  "name": "@corra/booth-ui",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 0.0.0.0",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint booth-ui\"",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/booth-core": "workspace:*",
    "@corra/image-engine": "workspace:*",
    "@corra/shared": "workspace:*",
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.3",
    "typescript": "^5.7.2",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {}
}'

write_if_missing "apps/booth-ui/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "noEmit": true
  },
  "include": ["src", "vite.config.ts"]
}'

write_if_missing "apps/booth-ui/vite.config.ts" 'import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173
  }
});
'

write_if_missing "apps/booth-ui/index.html" '<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Corra Booth</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'

write_if_missing "apps/booth-ui/src/main.tsx" 'import React from "react";
import ReactDOM from "react-dom/client";
import { App } from "./app/App";
import "./styles/index.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
'

write_if_missing "apps/booth-ui/src/app/App.tsx" 'export function App() {
  return (
    <main>
      <h1>Corra Booth</h1>
      <p>Phase 0 initialized successfully.</p>
    </main>
  );
}
'

write_if_missing "apps/booth-ui/src/styles/index.css" 'html,
body,
#root {
  width: 100%;
  min-height: 100%;
  margin: 0;
}

body {
  font-family: system-ui, sans-serif;
}
'

write_if_missing "apps/desktop-electron/package.json" '{
  "name": "@corra/desktop-electron",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "main": "dist/main/main.js",
  "scripts": {
    "dev": "echo \"Electron dev will be configured in Phase 4\"",
    "build": "echo \"Electron build will be configured in Phase 4\"",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint desktop-electron\"",
    "clean": "rm -rf dist release"
  },
  "dependencies": {
    "@corra/booth-core": "workspace:*",
    "@corra/data-access": "workspace:*",
    "@corra/shared": "workspace:*",
    "electron": "^33.2.1"
  },
  "devDependencies": {
    "electron-builder": "^25.1.8",
    "typescript": "^5.7.2"
  }
}'

write_if_missing "apps/desktop-electron/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist",
    "noEmit": false
  },
  "include": ["electron/**/*.ts"]
}'

write_if_missing "apps/desktop-electron/electron/main/main.ts" 'console.log("Corra Booth Electron main process placeholder.");
'

write_if_missing "apps/desktop-electron/electron/preload/index.ts" 'console.log("Corra Booth preload placeholder.");
'

write_if_missing "apps/desktop-electron/electron-builder.yml" 'appId: com.corrabooth.desktop
productName: Corra Booth
directories:
  output: release
files:
  - dist/**
  - resources/**
win:
  target:
    - nsis
  icon: resources/app-icon.ico
nsis:
  oneClick: false
  allowToChangeInstallationDirectory: true
'

write_if_missing "apps/admin-web/package.json" '{
  "name": "@corra/admin-web",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0 --port 5174",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 0.0.0.0",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint admin-web\"",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/data-access": "workspace:*",
    "@corra/shared": "workspace:*",
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.3",
    "typescript": "^5.7.2",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}'

write_if_missing "apps/admin-web/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "include": ["src", "vite.config.ts"]
}'

write_if_missing "apps/admin-web/vite.config.ts" 'import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5174
  }
});
'

write_if_missing "apps/admin-web/netlify.toml" '[build]
  command = "pnpm build"
  publish = "dist"
'

write_if_missing "apps/admin-web/index.html" '<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Corra Booth Admin</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'

write_if_missing "apps/admin-web/src/main.tsx" 'import React from "react";
import ReactDOM from "react-dom/client";

function AdminApp() {
  return <h1>Corra Booth Admin</h1>;
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <AdminApp />
  </React.StrictMode>
);
'

write_if_missing "apps/download-page/package.json" '{
  "name": "@corra/download-page",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0 --port 5175",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 0.0.0.0",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint download-page\"",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/shared": "workspace:*",
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.3",
    "typescript": "^5.7.2",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}'

write_if_missing "apps/download-page/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "include": ["src", "vite.config.ts"]
}'

write_if_missing "apps/download-page/vite.config.ts" 'import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5175
  }
});
'

write_if_missing "apps/download-page/netlify.toml" '[build]
  command = "pnpm build"
  publish = "dist"
'

write_if_missing "apps/download-page/index.html" '<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Corra Booth Download</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'

write_if_missing "apps/download-page/src/main.tsx" 'import React from "react";
import ReactDOM from "react-dom/client";

function DownloadApp() {
  return <h1>Corra Booth Download Page</h1>;
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <DownloadApp />
  </React.StrictMode>
);
'

write_if_missing "apps/landing-page/package.json" '{
  "name": "@corra/landing-page",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite --host 0.0.0.0 --port 5176",
    "build": "tsc -b && vite build",
    "preview": "vite preview --host 0.0.0.0",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint landing-page\"",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/shared": "workspace:*",
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.3",
    "typescript": "^5.7.2",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}'

write_if_missing "apps/landing-page/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "include": ["src", "vite.config.ts"]
}'

write_if_missing "apps/landing-page/vite.config.ts" 'import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5176
  }
});
'

write_if_missing "apps/landing-page/netlify.toml" '[build]
  command = "pnpm build"
  publish = "dist"
'

write_if_missing "apps/landing-page/index.html" '<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Corra Booth</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'

write_if_missing "apps/landing-page/src/main.tsx" 'import React from "react";
import ReactDOM from "react-dom/client";

function LandingApp() {
  return <h1>Corra Booth Landing Page</h1>;
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <LandingApp />
  </React.StrictMode>
);
'

echo ""
echo "Creating package manifests..."

write_if_missing "packages/booth-core/package.json" '{
  "name": "@corra/booth-core",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint booth-core\"",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/shared": "workspace:*"
  },
  "devDependencies": {
    "typescript": "^5.7.2"
  }
}'

write_if_missing "packages/booth-core/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "include": ["src"]
}'

write_if_missing "packages/booth-core/src/index.ts" 'export {};
'

write_if_missing "packages/image-engine/package.json" '{
  "name": "@corra/image-engine",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint image-engine\"",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/shared": "workspace:*"
  },
  "devDependencies": {
    "typescript": "^5.7.2"
  }
}'

write_if_missing "packages/image-engine/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "include": ["src"]
}'

write_if_missing "packages/image-engine/src/index.ts" 'export {};
'

write_if_missing "packages/data-access/package.json" '{
  "name": "@corra/data-access",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint data-access\"",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@corra/shared": "workspace:*",
    "@supabase/supabase-js": "^2.47.10"
  },
  "devDependencies": {
    "typescript": "^5.7.2"
  }
}'

write_if_missing "packages/data-access/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "include": ["src"]
}'

write_if_missing "packages/data-access/src/index.ts" 'export {};
'

write_if_missing "packages/shared/package.json" '{
  "name": "@corra/shared",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "build": "tsc -b",
    "typecheck": "tsc --noEmit",
    "lint": "echo \"lint shared\"",
    "clean": "rm -rf dist"
  },
  "devDependencies": {
    "typescript": "^5.7.2"
  }
}'

write_if_missing "packages/shared/tsconfig.json" '{
  "extends": "../../tsconfig.base.json",
  "include": ["src"]
}'

write_if_missing "packages/shared/src/index.ts" 'export {};
'

write_if_missing "packages/config/package.json" '{
  "name": "@corra/config",
  "private": true,
  "version": "0.1.0",
  "type": "module"
}'

echo ""
echo "Creating architecture docs..."

write_if_missing "docs/architecture.md" '# Corra Booth Architecture

Corra Booth is designed as a portable core application with platform adapters.

## Rule

The UI must not directly access Windows hardware SDKs.

Correct flow:

React UI → Platform API → Electron Preload → IPC → Electron Main → Windows Native Adapter

## Apps

- booth-ui: portable photobooth interface
- desktop-electron: Windows shell and native adapter
- admin-web: remote admin dashboard
- download-page: public QR download page
- landing-page: marketing site

## Packages

- booth-core: business rules
- image-engine: frame composition and GIF generation
- data-access: Supabase and local persistence
- shared: shared types and validators
'

write_if_missing "docs/session-vs-single-mode.md" '# Session Mode vs Single Mode

Strict rule:

- Session Mode is timer-based.
- Single Mode is frame-count-based.

Do not mix the logic.

## Session Mode

The user can generate as many frames as possible while the countdown timer is active.

## Single Mode

The user generates a fixed number of frames. No countdown timer controls the session duration.
'

write_if_missing "docs/license-flow.md" '# License Flow

Planned flow:

Mayar payment success → Mayar webhook → Supabase Edge Function → licenses table updated → Electron app verifies license status.

Electron must never store Mayar secret keys or Supabase service-role keys.
'

write_if_missing "docs/hardware-integration.md" '# Hardware Integration

Windows hardware integrations live only in:

apps/desktop-electron/electron/main/native/windows

The portable booth UI and booth core must communicate through ports/interfaces.
'

write_if_missing "docs/database-schema.md" '# Database Schema

Planned Supabase tables:

- licenses
- booth_devices
- license_activations
- transactions
- photo_sessions
- photo_assets
- templates
- layouts
- vouchers
- admin_users
'

write_if_missing "docs/deployment.md" '# Deployment

Planned deployment targets:

- Desktop app: Windows .exe via electron-builder
- Admin web: Netlify
- Download page: Netlify
- Landing page: Netlify
- Backend: Supabase
'

echo ""
echo "Creating infra placeholder files..."

write_if_missing "infra/supabase/seed.sql" '-- Corra Booth seed data placeholder
'

write_if_missing "infra/supabase/migrations/README.md" '# Supabase Migrations

SQL migrations will be added in later phases.
'

write_if_missing "infra/supabase/functions/mayar-webhook/index.ts" '// Mayar webhook Supabase Edge Function placeholder.
'

write_if_missing "infra/supabase/functions/verify-license/index.ts" '// Verify license Supabase Edge Function placeholder.
'

write_if_missing "infra/supabase/functions/create-download-token/index.ts" '// Create download token Supabase Edge Function placeholder.
'

write_if_missing "infra/supabase/functions/cleanup-expired-assets/index.ts" '// Cleanup expired assets Supabase Edge Function placeholder.
'

write_if_missing "infra/netlify/admin-web.toml" '[build]
  command = "pnpm --filter @corra/admin-web build"
  publish = "apps/admin-web/dist"
'

write_if_missing "infra/netlify/download-page.toml" '[build]
  command = "pnpm --filter @corra/download-page build"
  publish = "apps/download-page/dist"
'

write_if_missing "infra/netlify/landing-page.toml" '[build]
  command = "pnpm --filter @corra/landing-page build"
  publish = "apps/landing-page/dist"
'

echo ""
echo "Installing dependencies..."
pnpm install

echo ""
echo "Running typecheck..."
pnpm typecheck || true

echo ""
echo "========================================"
echo " Phase 0 completed."
echo "========================================"
echo ""
echo "Next commands:"
echo "  pnpm dev:ui"
echo ""
echo "Recommended git commit:"
echo "  git add ."
echo "  git commit -m \"chore: initialize corra booth monorepo\""
echo ""
