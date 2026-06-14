#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 7D1.1 Fix Admin Login Gate"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

[ -f "apps/booth-ui/src/App.tsx" ] || fail "App.tsx not found."
[ -f "apps/booth-ui/src/components/AdminLoginScreen.tsx" ] || fail "AdminLoginScreen not found. Run 7D1 first."

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/App.tsx")
text = path.read_text()

original = text

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
        raise SystemExit("Could not find addLog marker.")
    text = text.replace(
        marker,
        """  const handleAdminLoginSuccess = () => {
    setIsAdminAuthenticated(true);
    addLog('[ADMIN] Admin login success.');
  };

""" + marker
    )

# Force AdminPanel to require authenticated admin session.
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

# If AdminPanel uses ternary style, keep this simple fallback.
text = text.replace(
    "isAdminActive ? <AdminPanel",
    "isAdminActive && isAdminAuthenticated ? <AdminPanel",
)

# Insert login overlay before AdminPanel block if not already present.
if "isAdminActive && !isAdminAuthenticated" not in text:
    admin_panel_marker = "{isAdminActive && isAdminAuthenticated && ("
    if admin_panel_marker in text:
        login_block = """{isAdminActive && !isAdminAuthenticated && (
        <AdminLoginScreen
          onLoginSuccess={handleAdminLoginSuccess}
          onCancel={() => {
            setIsAdminActive(false);
            setIsAdminAuthenticated(false);
          }}
        />
      )}

      """
        text = text.replace(admin_panel_marker, login_block + admin_panel_marker, 1)
    else:
        # Fallback: insert before screen router.
        marker = "{/* Screen Render routers */}"
        if marker not in text:
            raise SystemExit("Could not find AdminPanel gate or screen router marker.")
        login_block = """{isAdminActive && !isAdminAuthenticated && (
        <AdminLoginScreen
          onLoginSuccess={handleAdminLoginSuccess}
          onCancel={() => {
            setIsAdminActive(false);
            setIsAdminAuthenticated(false);
          }}
        />
      )}

      """
        text = text.replace(marker, login_block + marker, 1)

# Make sure closing admin also clears current admin session on obvious onClose pattern.
text = text.replace(
    "onClose={() => setIsAdminActive(false)}",
    """onClose={() => {
          setIsAdminActive(false);
          setIsAdminAuthenticated(false);
        }}"""
)

path.write_text(text)

if text == original:
    print("No changes made. App.tsx may already be patched.")
else:
    print("PATCH file: apps/booth-ui/src/App.tsx")

print("")
print("Admin-related lines:")
for i, line in enumerate(text.splitlines(), start=1):
    if "AdminLoginScreen" in line or "AdminPanel" in line or "isAdminAuthenticated" in line or "isAdminActive" in line:
        print(f"{i}: {line}")
PY

echo ""
echo "Verifying..."

grep -q "isAdminActive && !isAdminAuthenticated" apps/booth-ui/src/App.tsx || fail "Login gate missing."
grep -q "isAdminActive && isAdminAuthenticated" apps/booth-ui/src/App.tsx || fail "AdminPanel auth gate missing."
grep -q "AdminLoginScreen" apps/booth-ui/src/App.tsx || fail "AdminLoginScreen missing from App.tsx."

echo ""
echo "========================================"
echo " Phase 7D1.1 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  pnpm --filter @corra/booth-ui dev -- --host 0.0.0.0 --port 5173"
echo ""
