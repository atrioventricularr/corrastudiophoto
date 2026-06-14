#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - 7D1.2 Hard Fix Admin Login"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

write_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
  echo "WRITE file: $file_path"
}

[ -f "apps/booth-ui/src/App.tsx" ] || fail "App.tsx not found."
[ -f "apps/booth-ui/src/branding/index.ts" ] || fail "Branding foundation missing."

echo ""
echo "Writing simple admin auth helper..."

write_file "apps/booth-ui/src/lib/admin-auth.ts" <<'TS'
export const DEFAULT_ADMIN_USERNAME = 'admin';
export const DEFAULT_ADMIN_PASSWORD = 'admin123';

export type AdminCredentialConfig = {
  username: string;
  passwordHash: string | null;
  isDefaultCredential: boolean;
  updatedAt: string | null;
};

const STORAGE_KEY = 'corra.adminCredential.v1';

async function sha256(value: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(value);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);

  return Array.from(new Uint8Array(hashBuffer))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

export function getAdminCredentialConfig(): AdminCredentialConfig {
  if (typeof window === 'undefined') {
    return {
      username: DEFAULT_ADMIN_USERNAME,
      passwordHash: null,
      isDefaultCredential: true,
      updatedAt: null,
    };
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return {
        username: DEFAULT_ADMIN_USERNAME,
        passwordHash: null,
        isDefaultCredential: true,
        updatedAt: null,
      };
    }

    const parsed = JSON.parse(raw) as Partial<AdminCredentialConfig>;

    return {
      username: parsed.username || DEFAULT_ADMIN_USERNAME,
      passwordHash: parsed.passwordHash || null,
      isDefaultCredential: Boolean(parsed.isDefaultCredential),
      updatedAt: parsed.updatedAt || null,
    };
  } catch {
    return {
      username: DEFAULT_ADMIN_USERNAME,
      passwordHash: null,
      isDefaultCredential: true,
      updatedAt: null,
    };
  }
}

export async function verifyAdminCredential(
  username: string,
  password: string,
): Promise<boolean> {
  const config = getAdminCredentialConfig();
  const normalizedUsername = username.trim();
  const normalizedPassword = password.trim();

  if (!config.passwordHash) {
    return (
      normalizedUsername === DEFAULT_ADMIN_USERNAME &&
      normalizedPassword === DEFAULT_ADMIN_PASSWORD
    );
  }

  if (normalizedUsername !== config.username) {
    return false;
  }

  return (await sha256(normalizedPassword)) === config.passwordHash;
}

export async function saveAdminCredential(
  username: string,
  password: string,
): Promise<AdminCredentialConfig> {
  const nextConfig: AdminCredentialConfig = {
    username: username.trim() || DEFAULT_ADMIN_USERNAME,
    passwordHash: await sha256(password),
    isDefaultCredential: false,
    updatedAt: new Date().toISOString(),
  };

  if (typeof window !== 'undefined') {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(nextConfig));
  }

  return nextConfig;
}
TS

echo ""
echo "Writing simple AdminLoginScreen..."

write_file "apps/booth-ui/src/components/AdminLoginScreen.tsx" <<'TSX'
import React, { useMemo, useState } from 'react';
import {
  DEFAULT_ADMIN_PASSWORD,
  DEFAULT_ADMIN_USERNAME,
  getAdminCredentialConfig,
  verifyAdminCredential,
} from '../lib/admin-auth';
import { useBrandTheme } from '../branding';

type AdminLoginScreenProps = {
  onLoginSuccess: () => void;
  onCancel: () => void;
};

export default function AdminLoginScreen({
  onLoginSuccess,
  onCancel,
}: AdminLoginScreenProps) {
  const { brandConfig } = useBrandTheme();
  const credentialConfig = useMemo(() => getAdminCredentialConfig(), []);
  const [username, setUsername] = useState(credentialConfig.username || DEFAULT_ADMIN_USERNAME);
  const [password, setPassword] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  const handleSubmit = async () => {
    setErrorMessage('');

    const isValid = await verifyAdminCredential(username, password);

    if (!isValid) {
      setErrorMessage('Username atau password salah.');
      return;
    }

    onLoginSuccess();
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 999999,
        background: 'rgba(0, 0, 0, 0.45)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 24,
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: 460,
          borderRadius: 28,
          background: 'white',
          border: '1px solid var(--corra-border)',
          boxShadow: '0 32px 120px rgba(0,0,0,0.30)',
          padding: 28,
          color: 'var(--corra-text)',
          fontFamily: 'var(--corra-font-body)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16 }}>
          <div>
            <p
              style={{
                margin: 0,
                fontSize: 12,
                fontWeight: 900,
                letterSpacing: '0.16em',
                textTransform: 'uppercase',
                color: 'var(--corra-primary)',
              }}
            >
              Admin Login
            </p>
            <h1
              style={{
                margin: '8px 0 0',
                fontFamily: 'var(--corra-font-heading)',
                fontSize: 32,
                lineHeight: 1.05,
              }}
            >
              {brandConfig.businessName || 'Corra Booth'}
            </h1>
          </div>

          <button
            type="button"
            onClick={onCancel}
            style={{
              width: 40,
              height: 40,
              borderRadius: 999,
              border: '1px solid var(--corra-border)',
              background: 'white',
              cursor: 'pointer',
              fontWeight: 900,
            }}
          >
            ×
          </button>
        </div>

        {credentialConfig.isDefaultCredential && (
          <div
            style={{
              marginTop: 18,
              padding: 14,
              borderRadius: 18,
              background: '#FFF7ED',
              border: '1px solid #FED7AA',
              color: '#9A3412',
              fontSize: 13,
              lineHeight: 1.5,
            }}
          >
            Default login aktif: <b>{DEFAULT_ADMIN_USERNAME}</b> /{' '}
            <b>{DEFAULT_ADMIN_PASSWORD}</b>. Nanti ganti di Admin Settings.
          </div>
        )}

        <div style={{ marginTop: 20 }}>
          <label style={{ display: 'block', fontSize: 12, fontWeight: 900, marginBottom: 8 }}>
            Username
          </label>
          <input
            value={username}
            onChange={(event) => setUsername(event.target.value)}
            style={{
              width: '100%',
              height: 50,
              borderRadius: 16,
              border: '1px solid var(--corra-border)',
              padding: '0 14px',
              fontSize: 15,
              boxSizing: 'border-box',
            }}
          />
        </div>

        <div style={{ marginTop: 14 }}>
          <label style={{ display: 'block', fontSize: 12, fontWeight: 900, marginBottom: 8 }}>
            Password
          </label>
          <input
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                handleSubmit();
              }
            }}
            type="password"
            placeholder="admin123"
            style={{
              width: '100%',
              height: 50,
              borderRadius: 16,
              border: '1px solid var(--corra-border)',
              padding: '0 14px',
              fontSize: 15,
              boxSizing: 'border-box',
            }}
          />
        </div>

        {errorMessage && (
          <div
            style={{
              marginTop: 14,
              padding: 12,
              borderRadius: 14,
              background: '#FEF2F2',
              border: '1px solid #FECACA',
              color: '#B91C1C',
              fontSize: 13,
              fontWeight: 800,
            }}
          >
            {errorMessage}
          </div>
        )}

        <button
          type="button"
          onClick={handleSubmit}
          style={{
            marginTop: 20,
            width: '100%',
            height: 54,
            borderRadius: 18,
            border: 0,
            background: 'var(--corra-primary)',
            color: 'white',
            fontWeight: 900,
            fontSize: 14,
            letterSpacing: '0.08em',
            cursor: 'pointer',
          }}
        >
          LOGIN ADMIN
        </button>
      </div>
    </div>
  );
}
TSX

echo ""
echo "Patching App.tsx with visible admin login gate..."

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/App.tsx")
text = path.read_text()

if "AdminLoginScreen" not in text:
    text = text.replace(
        "import AdminPanel from './components/AdminPanel';",
        "import AdminPanel from './components/AdminPanel';\nimport AdminLoginScreen from './components/AdminLoginScreen';"
    )

if "const [isAdminAuthenticated, setIsAdminAuthenticated]" not in text:
    text = text.replace(
        "const [isAdminActive, setIsAdminActive] = useState<boolean>(false);",
        "const [isAdminActive, setIsAdminActive] = useState<boolean>(false);\n  const [isAdminAuthenticated, setIsAdminAuthenticated] = useState<boolean>(false);"
    )

if "handleAdminLoginSuccess" not in text:
    marker = "  const addLog = (message: string) => {"
    if marker not in text:
        raise SystemExit("Could not find addLog marker in App.tsx")
    text = text.replace(
        marker,
        """  const handleAdminLoginSuccess = () => {
    setIsAdminAuthenticated(true);
    addLog('[ADMIN] Admin login success.');
  };

""" + marker
    )

# Force existing AdminPanel gates to require authentication.
text = re.sub(
    r"\{\s*isAdminActive\s*&&\s*\(\s*<AdminPanel",
    "{isAdminActive && isAdminAuthenticated && (\n        <AdminPanel",
    text,
)
text = re.sub(
    r"\{\s*isAdminActive\s*&&\s*<AdminPanel",
    "{isAdminActive && isAdminAuthenticated && <AdminPanel",
    text,
)

# Add a very visible login gate once.
if "ADMIN_LOGIN_GATE_HARD_FIX" not in text:
    marker = "{/* Screen Render routers */}"
    if marker not in text:
        raise SystemExit("Could not find Screen Render routers marker in App.tsx")

    block = """{/* ADMIN_LOGIN_GATE_HARD_FIX */}
      {isAdminActive && !isAdminAuthenticated && (
        <AdminLoginScreen
          onLoginSuccess={handleAdminLoginSuccess}
          onCancel={() => {
            setIsAdminActive(false);
            setIsAdminAuthenticated(false);
          }}
        />
      )}

      """

    text = text.replace(marker, block + marker)

path.write_text(text)
print("PATCH file: apps/booth-ui/src/App.tsx")
PY

echo ""
echo "Verifying..."

[ -f "apps/booth-ui/src/components/AdminLoginScreen.tsx" ] || fail "AdminLoginScreen still missing."
grep -q "ADMIN_LOGIN_GATE_HARD_FIX" apps/booth-ui/src/App.tsx || fail "Hard login gate missing."
grep -q "isAdminActive && !isAdminAuthenticated" apps/booth-ui/src/App.tsx || fail "Login condition missing."

echo ""
echo "========================================"
echo " 7D1.2 hard fix completed."
echo "========================================"
