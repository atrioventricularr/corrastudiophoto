#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - 7D1.3 Fix Admin Login Cancel"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

[ -f "apps/booth-ui/src/App.tsx" ] || fail "App.tsx not found."
[ -f "apps/booth-ui/src/components/AdminLoginScreen.tsx" ] || fail "AdminLoginScreen.tsx not found."

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/App.tsx")
text = path.read_text()

# Ensure admin auth state exists.
if "const [isAdminAuthenticated, setIsAdminAuthenticated]" not in text:
    text = text.replace(
        "const [isAdminActive, setIsAdminActive] = useState<boolean>(false);",
        "const [isAdminActive, setIsAdminActive] = useState<boolean>(false);\n  const [isAdminAuthenticated, setIsAdminAuthenticated] = useState<boolean>(false);"
    )

# Ensure success handler exists.
if "const handleAdminLoginSuccess" not in text:
    marker = "  const handleStartSession"
    if marker not in text:
        marker = "  return ("
    text = text.replace(
        marker,
        """  const handleAdminLoginSuccess = () => {
    setIsAdminAuthenticated(true);
    setIsAdminActive(true);
    addLog('[ADMIN] Admin login success.');
  };

""" + marker,
        1
    )

# Ensure cancel handler exists.
if "const handleAdminLoginCancel" not in text:
    marker = "  const handleAdminLoginSuccess"
    if marker in text:
        text = text.replace(
            marker,
            """  const handleAdminLoginCancel = () => {
    setIsAdminAuthenticated(false);
    setIsAdminActive(false);
    setActiveScreen('welcome');
    addLog('[ADMIN] Admin login cancelled.');
  };

""" + marker,
            1
        )
    else:
        marker = "  const handleStartSession"
        text = text.replace(
            marker,
            """  const handleAdminLoginCancel = () => {
    setIsAdminAuthenticated(false);
    setIsAdminActive(false);
    setActiveScreen('welcome');
    addLog('[ADMIN] Admin login cancelled.');
  };

"""+ marker,
            1
        )

# Replace every AdminLoginScreen onCancel with the safe cancel handler.
text = re.sub(
    r"onCancel=\{\(\) => \{\s*setIsAdminActive\(false\);\s*setIsAdminAuthenticated\(false\);\s*\}\}",
    "onCancel={handleAdminLoginCancel}",
    text,
    flags=re.S
)

text = re.sub(
    r"onCancel=\{\(\) => setIsAdminActive\(false\)\}",
    "onCancel={handleAdminLoginCancel}",
    text
)

# If any login block still uses custom cancel, force it.
text = text.replace(
    "onCancel={() => {\n            setIsAdminActive(false);\n            setIsAdminAuthenticated(false);\n          }}",
    "onCancel={handleAdminLoginCancel}"
)

# Force AdminPanel render to require authentication.
text = re.sub(
    r"\{\s*isAdminActive\s*&&\s*\(\s*<AdminPanel",
    "{isAdminActive && isAdminAuthenticated && (\n        <AdminPanel",
    text,
    flags=re.S
)

text = re.sub(
    r"\{\s*isAdminActive\s*&&\s*<AdminPanel",
    "{isAdminActive && isAdminAuthenticated && <AdminPanel",
    text
)

# Fix repeated accidental condition.
text = text.replace(
    "isAdminActive && isAdminAuthenticated && isAdminAuthenticated",
    "isAdminActive && isAdminAuthenticated"
)

# Make AdminPanel close also clear authenticated state.
text = re.sub(
    r"onClose=\{\(\) => setIsAdminActive\(false\)\}",
    """onClose={() => {
          setIsAdminActive(false);
          setIsAdminAuthenticated(false);
        }}""",
    text
)

path.write_text(text)
print("PATCH file: apps/booth-ui/src/App.tsx")

print("")
print("Admin gate lines:")
for i, line in enumerate(text.splitlines(), start=1):
    if (
        "AdminLoginScreen" in line
        or "AdminPanel" in line
        or "isAdminActive" in line
        or "isAdminAuthenticated" in line
        or "handleAdminLoginCancel" in line
        or "handleAdminLoginSuccess" in line
    ):
        print(f"{i}: {line}")
PY

echo ""
echo "Verifying..."

grep -q "handleAdminLoginCancel" apps/booth-ui/src/App.tsx || fail "Missing handleAdminLoginCancel."
grep -q "onCancel={handleAdminLoginCancel}" apps/booth-ui/src/App.tsx || fail "AdminLoginScreen cancel not wired."
grep -q "isAdminActive && isAdminAuthenticated" apps/booth-ui/src/App.tsx || fail "AdminPanel is not auth-gated."

echo ""
echo "========================================"
echo " 7D1.3 completed."
echo "========================================"
