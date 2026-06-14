#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 7D2 Admin Credential Settings"
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

[ -f "apps/booth-ui/src/components/AdminPanel.tsx" ] || fail "AdminPanel.tsx not found."
[ -f "apps/booth-ui/src/lib/admin-auth.ts" ] || fail "admin-auth.ts not found. Run 7D1 first."

echo ""
echo "Writing AdminCredentialPanel..."

write_file "apps/booth-ui/src/components/admin/AdminCredentialPanel.tsx" <<'TSX'
import React, { useMemo, useState } from 'react';
import {
  DEFAULT_ADMIN_PASSWORD,
  DEFAULT_ADMIN_USERNAME,
  getAdminCredentialConfig,
  saveAdminCredential,
  verifyAdminCredential,
} from '../../lib/admin-auth';

export default function AdminCredentialPanel() {
  const initialConfig = useMemo(() => getAdminCredentialConfig(), []);
  const [currentUsername, setCurrentUsername] = useState(
    initialConfig.username || DEFAULT_ADMIN_USERNAME,
  );
  const [currentPassword, setCurrentPassword] = useState('');
  const [newUsername, setNewUsername] = useState(
    initialConfig.username || DEFAULT_ADMIN_USERNAME,
  );
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isDefaultActive, setIsDefaultActive] = useState(
    initialConfig.isDefaultCredential,
  );
  const [message, setMessage] = useState<{
    type: 'success' | 'error' | 'info';
    text: string;
  } | null>(
    initialConfig.isDefaultCredential
      ? {
          type: 'info',
          text: `Default login aktif: ${DEFAULT_ADMIN_USERNAME} / ${DEFAULT_ADMIN_PASSWORD}. Segera ganti sebelum digunakan customer.`,
        }
      : null,
  );
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async () => {
    setMessage(null);

    const trimmedCurrentUsername = currentUsername.trim();
    const trimmedNewUsername = newUsername.trim();

    if (!trimmedCurrentUsername || !currentPassword.trim()) {
      setMessage({
        type: 'error',
        text: 'Masukkan current username dan current password.',
      });
      return;
    }

    if (!trimmedNewUsername) {
      setMessage({
        type: 'error',
        text: 'Username baru tidak boleh kosong.',
      });
      return;
    }

    if (newPassword.length < 6) {
      setMessage({
        type: 'error',
        text: 'Password baru minimal 6 karakter.',
      });
      return;
    }

    if (newPassword !== confirmPassword) {
      setMessage({
        type: 'error',
        text: 'Konfirmasi password tidak sama.',
      });
      return;
    }

    setIsSaving(true);

    try {
      const isCurrentValid = await verifyAdminCredential(
        trimmedCurrentUsername,
        currentPassword,
      );

      if (!isCurrentValid) {
        setMessage({
          type: 'error',
          text: 'Current username/password salah.',
        });
        return;
      }

      const saved = await saveAdminCredential(trimmedNewUsername, newPassword);

      setCurrentUsername(saved.username);
      setNewUsername(saved.username);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      setIsDefaultActive(saved.isDefaultCredential);

      setMessage({
        type: 'success',
        text: 'Admin username/password berhasil diganti.',
      });
    } catch (error) {
      setMessage({
        type: 'error',
        text:
          error instanceof Error
            ? error.message
            : 'Gagal menyimpan admin credential.',
      });
    } finally {
      setIsSaving(false);
    }
  };

  const messageClassName =
    message?.type === 'success'
      ? 'border-emerald-200 bg-emerald-50 text-emerald-800'
      : message?.type === 'error'
        ? 'border-red-200 bg-red-50 text-red-800'
        : 'border-amber-200 bg-amber-50 text-amber-800';

  return (
    <div className="rounded-3xl border border-[var(--corra-border)] bg-[var(--corra-surface)] p-6 text-[var(--corra-text)]">
      <div className="mb-5">
        <h2 className="font-black text-2xl">Admin Credential</h2>
        <p className="text-sm text-[var(--corra-muted)]">
          Ganti username dan password untuk membuka Admin Panel.
        </p>
      </div>

      {isDefaultActive && (
        <div className="mb-5 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
          <p className="font-black">Default credential masih aktif</p>
          <p className="mt-1">
            Login awal adalah <b>{DEFAULT_ADMIN_USERNAME}</b> /{' '}
            <b>{DEFAULT_ADMIN_PASSWORD}</b>. Ganti sebelum app dipakai customer.
          </p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Current Username
          </span>
          <input
            value={currentUsername}
            onChange={(event) => setCurrentUsername(event.target.value)}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
            autoComplete="username"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Current Password
          </span>
          <input
            value={currentPassword}
            onChange={(event) => setCurrentPassword(event.target.value)}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
            type="password"
            autoComplete="current-password"
            placeholder={isDefaultActive ? DEFAULT_ADMIN_PASSWORD : 'Current password'}
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            New Username
          </span>
          <input
            value={newUsername}
            onChange={(event) => setNewUsername(event.target.value)}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
            autoComplete="username"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            New Password
          </span>
          <input
            value={newPassword}
            onChange={(event) => setNewPassword(event.target.value)}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
            type="password"
            autoComplete="new-password"
            placeholder="Minimal 6 karakter"
          />
        </label>

        <label className="space-y-2 md:col-span-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Confirm New Password
          </span>
          <input
            value={confirmPassword}
            onChange={(event) => setConfirmPassword(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter') {
                handleSave();
              }
            }}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
            type="password"
            autoComplete="new-password"
            placeholder="Ulangi password baru"
          />
        </label>
      </div>

      {message && (
        <div className={`mt-5 rounded-2xl border p-4 text-sm font-bold ${messageClassName}`}>
          {message.text}
        </div>
      )}

      <button
        type="button"
        onClick={handleSave}
        disabled={isSaving}
        className="mt-5 rounded-2xl bg-[var(--corra-primary)] px-5 py-3 text-sm font-black text-white disabled:opacity-60"
      >
        {isSaving ? 'Saving...' : 'Save Admin Credential'}
      </button>

      <p className="mt-4 text-xs leading-relaxed text-[var(--corra-muted)]">
        Catatan: versi ini masih menyimpan credential di local browser storage
        untuk development. Versi production akan dipindah ke Electron encrypted
        local settings.
      </p>
    </div>
  );
}
TSX

echo ""
echo "Patching AdminPanel..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

if "AdminCredentialPanel" not in text:
    # Try to place import near BrandAppearancePanel if it exists.
    if "BrandAppearancePanel from './admin/BrandAppearancePanel';" in text:
        text = text.replace(
            "import BrandAppearancePanel from './admin/BrandAppearancePanel';",
            "import BrandAppearancePanel from './admin/BrandAppearancePanel';\nimport AdminCredentialPanel from './admin/AdminCredentialPanel';"
        )
    else:
        # Fallback: append after first import block.
        lines = text.splitlines()
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
        lines.insert(insert_at, "import AdminCredentialPanel from './admin/AdminCredentialPanel';")
        text = "\n".join(lines) + "\n"

if "<AdminCredentialPanel />" not in text:
    if "<BrandAppearancePanel />" in text:
        text = text.replace(
            "<BrandAppearancePanel />",
            "<BrandAppearancePanel />\n        <div className=\"mt-6\">\n          <AdminCredentialPanel />\n        </div>",
            1
        )
    else:
        marker = "      {/* Main double column form container */}"
        if marker in text:
            text = text.replace(
                marker,
                "      <div className=\"mt-6\">\n        <AdminCredentialPanel />\n      </div>\n\n" + marker,
                1
            )
        else:
            raise SystemExit("Could not find insertion point in AdminPanel.tsx")

path.write_text(text)
print("PATCH file: apps/booth-ui/src/components/AdminPanel.tsx")
PY

echo ""
echo "Writing docs..."

write_file "docs/phase-7d2-admin-credential-settings.md" <<'MD'
# Phase 7D2 - Admin Credential Settings

## Added

- AdminCredentialPanel in Admin Panel
- Change admin username
- Change admin password
- Current password verification
- Default admin/admin123 warning

## Default Credential

- username: admin
- password: admin123

## Security Note

This phase stores admin credentials in browser localStorage for development.
Production should move credential storage to Electron encrypted local settings.
MD

echo ""
echo "Verifying..."

[ -f "apps/booth-ui/src/components/admin/AdminCredentialPanel.tsx" ] || fail "Missing AdminCredentialPanel."
grep -q "AdminCredentialPanel" apps/booth-ui/src/components/AdminPanel.tsx || fail "AdminPanel missing AdminCredentialPanel."
grep -q "saveAdminCredential" apps/booth-ui/src/components/admin/AdminCredentialPanel.tsx || fail "Panel missing saveAdminCredential usage."

echo ""
echo "========================================"
echo " Phase 7D2 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  pnpm --filter @corra/booth-ui dev -- --host 0.0.0.0 --port 5173"
echo "  git add ."
echo "  git commit -m \"feat: add admin credential settings\""
echo "  git push origin main"
echo ""
