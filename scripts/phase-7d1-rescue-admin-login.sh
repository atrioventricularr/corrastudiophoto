#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - 7D1 Rescue Admin Login"
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
[ -f "apps/booth-ui/src/branding/index.ts" ] || fail "Branding foundation missing. Run 7C1 first."

echo ""
echo "Writing admin auth helper..."

write_file "apps/booth-ui/src/lib/admin-auth.ts" <<'TS'
export type AdminCredentialConfig = {
  username: string;
  passwordHash: string | null;
  isDefaultCredential: boolean;
  updatedAt: string | null;
};

const STORAGE_KEY = 'corra.adminCredential.v1';

export const DEFAULT_ADMIN_USERNAME = 'admin';
export const DEFAULT_ADMIN_PASSWORD = 'admin123';

async function sha256(value: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(value);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));

  return hashArray
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

  const attemptedHash = await sha256(normalizedPassword);

  return attemptedHash === config.passwordHash;
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
echo "Writing AdminLoginScreen..."

write_file "apps/booth-ui/src/components/AdminLoginScreen.tsx" <<'TSX'
import React, { useMemo, useState } from 'react';
import {
  AlertTriangle,
  LockKeyhole,
  LogIn,
  ShieldCheck,
  UserRound,
  X,
} from 'lucide-react';
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
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleLogin = async () => {
    setErrorMessage('');
    setIsSubmitting(true);

    try {
      const isValid = await verifyAdminCredential(username, password);

      if (!isValid) {
        setErrorMessage('Username atau password admin salah.');
        return;
      }

      onLoginSuccess();
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[9999] bg-black/50 backdrop-blur-sm flex items-center justify-center p-5">
      <div className="absolute inset-0" onClick={onCancel} />

      <section className="relative w-full max-w-md rounded-[var(--corra-radius)] border border-[var(--corra-border)] bg-[var(--corra-surface)] shadow-[0_24px_100px_rgba(0,0,0,0.28)] overflow-hidden text-[var(--corra-text)]">
        <div className="absolute inset-x-0 top-0 h-1 bg-[var(--corra-primary)]" />

        <button
          type="button"
          onClick={onCancel}
          className="absolute top-4 right-4 w-10 h-10 rounded-full border border-[var(--corra-border)] bg-white/70 flex items-center justify-center text-[var(--corra-muted)] hover:text-[var(--corra-text)] transition"
          aria-label="Close admin login"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="p-7 sm:p-8">
          <div className="inline-flex items-center gap-2 rounded-full border border-[var(--corra-border)] bg-white/70 px-4 py-2 text-xs font-black uppercase tracking-[0.18em] text-[var(--corra-primary)]">
            <ShieldCheck className="w-4 h-4" />
            Admin Access
          </div>

          <h1 className="mt-5 text-3xl font-black corra-heading">
            {brandConfig.businessName}
          </h1>

          <p className="mt-2 text-sm leading-relaxed text-[var(--corra-muted)]">
            Masuk sebagai admin untuk mengubah brand, theme, background, payment,
            camera, printer, dan pengaturan booth.
          </p>

          {credentialConfig.isDefaultCredential && (
            <div className="mt-5 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-amber-800">
              <div className="flex gap-3">
                <AlertTriangle className="w-5 h-5 shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-black">Default admin credential aktif</p>
                  <p className="mt-1 text-xs leading-relaxed">
                    Login awal: <b>{DEFAULT_ADMIN_USERNAME}</b> / <b>{DEFAULT_ADMIN_PASSWORD}</b>.
                    Nanti ganti password di Admin Settings.
                  </p>
                </div>
              </div>
            </div>
          )}

          <div className="mt-6 space-y-4">
            <label className="block">
              <span className="mb-2 block text-xs font-black uppercase tracking-wider text-[var(--corra-muted)]">
                Username
              </span>
              <div className="relative">
                <UserRound className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--corra-muted)]" />
                <input
                  value={username}
                  onChange={(event) => setUsername(event.target.value)}
                  className="h-14 w-full rounded-2xl border border-[var(--corra-border)] bg-white pl-12 pr-4 text-sm font-bold outline-none"
                  autoComplete="username"
                />
              </div>
            </label>

            <label className="block">
              <span className="mb-2 block text-xs font-black uppercase tracking-wider text-[var(--corra-muted)]">
                Password
              </span>
              <div className="relative">
                <LockKeyhole className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--corra-muted)]" />
                <input
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter') {
                      handleLogin();
                    }
                  }}
                  className="h-14 w-full rounded-2xl border border-[var(--corra-border)] bg-white pl-12 pr-4 text-sm font-bold outline-none"
                  type="password"
                  autoComplete="current-password"
                  placeholder="••••••••"
                />
              </div>
            </label>
          </div>

          {errorMessage && (
            <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-3 text-sm font-bold text-red-700">
              {errorMessage}
            </div>
          )}

          <button
            type="button"
            onClick={handleLogin}
            disabled={isSubmitting}
            className="mt-6 flex h-14 w-full items-center justify-center gap-2 rounded-2xl bg-[var(--corra-primary)] text-white font-black shadow-lg shadow-black/10 transition hover:scale-[1.01] active:scale-[0.99] disabled:opacity-60"
          >
            <LogIn className="w-5 h-5" />
            {isSubmitting ? 'CHECKING...' : 'LOGIN ADMIN'}
          </button>
        </div>
      </section>
    </div>
  );
}
TSX

echo ""
echo "Patching App.tsx admin gate..."

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
    text = text.replace(
        marker,
        """  const handleAdminLoginSuccess = () => {
    setIsAdminAuthenticated(true);
    addLog('[ADMIN] Admin login success.');
  };

""" + marker
    )

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

if "isAdminActive && !isAdminAuthenticated" not in text:
    marker = "{/* Screen Render routers */}"
    if marker not in text:
        raise SystemExit("Could not find screen router marker.")
    text = text.replace(
        marker,
        """{isAdminActive && !isAdminAuthenticated && (
        <AdminLoginScreen
          onLoginSuccess={handleAdminLoginSuccess}
          onCancel={() => {
            setIsAdminActive(false);
            setIsAdminAuthenticated(false);
          }}
        />
      )}

      """ + marker
    )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/App.tsx")
PY

echo ""
echo "Appending theme font CSS if missing..."

grep -q "Corra theme typography" apps/booth-ui/src/index.css || cat >> apps/booth-ui/src/index.css <<'CSS'

/* Corra theme typography + global token usage */
html,
body,
#root {
  font-family: var(--corra-font-body);
  color: var(--corra-text);
}

button,
input,
select,
textarea {
  font-family: var(--corra-font-body);
}

h1,
h2,
h3,
h4,
h5,
h6,
.font-serif,
.font-display,
.corra-heading {
  font-family: var(--corra-font-heading);
}

.corra-body {
  font-family: var(--corra-font-body);
}
CSS

echo ""
echo "Verifying..."

[ -f "apps/booth-ui/src/lib/admin-auth.ts" ] || fail "Missing admin-auth.ts."
[ -f "apps/booth-ui/src/components/AdminLoginScreen.tsx" ] || fail "Missing AdminLoginScreen."
grep -q "isAdminActive && !isAdminAuthenticated" apps/booth-ui/src/App.tsx || fail "Missing login gate."
grep -q "isAdminAuthenticated" apps/booth-ui/src/App.tsx || fail "Missing admin auth state."

echo ""
echo "========================================"
echo " 7D1 rescue completed."
echo "========================================"
