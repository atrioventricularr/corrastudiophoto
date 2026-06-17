#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E1B1 - Connect Session Start + Payment"
echo "========================================"

FILE="apps/booth-ui/src/App.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: App.tsx not found."
  exit 1
}

[ -f "apps/booth-ui/src/sessions/index.ts" ] || {
  echo "ERROR: sessions module not found. Run 8E1A first."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/App.tsx")
text = path.read_text()

# 1. Add import
if "useSessionLifecycle" not in text:
    # Put near other local imports
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, "import { useSessionLifecycle } from './sessions';")
    text = "\n".join(lines) + "\n"

# 2. Add hook inside App component
if "startBoothSession" not in text:
    # Insert after function App opening before first useState block.
    match = re.search(r"(export default function App\(\)\s*\{\n)", text)
    if not match:
        match = re.search(r"(function App\(\)\s*\{\n)", text)

    if not match:
        raise SystemExit("Could not find App function opening.")

    hook = """  const {
    currentSession,
    startBoothSession,
    transitionBoothSession,
    cancelBoothSession,
  } = useSessionLifecycle();

"""
    text = text[:match.end()] + hook + text[match.end():]

# 3. Patch handleStartSession or equivalent
if "session_started_from_welcome" not in text:
    pattern = r"(const handleStartSession\s*=\s*\(\)\s*=>\s*\{\n)([\s\S]*?)(\n\s*\};)"
    match = re.search(pattern, text)

    if match:
        body = match.group(2)
        patch = """    const session = startBoothSession({
      metadata: {
        source: 'welcome_screen',
      },
    });

    transitionBoothSession({
      toStatus: 'payment_pending',
      reason: 'session_started_from_welcome',
      metadata: {
        sessionId: session.id,
      },
    });

"""
        text = text[:match.start(2)] + patch + body + text[match.end(2):]
    else:
        print("WARN: handleStartSession not found. Skipping start patch.")

# 4. Patch handlePaymentSuccess
if "payment_confirmed_from_payment_screen" not in text:
    pattern = r"(const handlePaymentSuccess\s*=\s*\(([^)]*)\)\s*=>\s*\{\n)([\s\S]*?)(\n\s*\};)"
    match = re.search(pattern, text)

    if match:
        params = match.group(2).strip()
        first_param = params.split(":")[0].split("=")[0].strip() if params else "voucherUsed"
        if not first_param:
            first_param = "voucherUsed"

        body = match.group(3)
        patch = f"""    transitionBoothSession({{
      toStatus: 'payment_confirmed',
      reason: 'payment_confirmed_from_payment_screen',
      patch: {{
        paymentConfirmationCode: {first_param} || 'PAYMENT_CONFIRMED',
        voucherCode:
          {first_param} && !String({first_param}).includes('CONFIRMED')
            ? {first_param}
            : null,
      }},
      metadata: {{
        paymentResult: {first_param} || 'PAYMENT_CONFIRMED',
      }},
    }});

"""
        text = text[:match.start(3)] + patch + body + text[match.end(3):]
    else:
        print("WARN: handlePaymentSuccess not found. Skipping payment patch.")

# 5. Patch back from payment if easy
if "payment_back_cancel_session" not in text:
    # Find PaymentScreen onBack prop and wrap it.
    text = text.replace(
        "onBack={() => setActiveScreen('welcome')}",
        """onBack={() => {
          cancelBoothSession('payment_back_cancel_session');
          setActiveScreen('welcome');
        }}"""
    )

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "useSessionLifecycle" "$FILE" || {
  echo "ERROR: App missing useSessionLifecycle."
  exit 1
}

grep -q "payment_confirmed_from_payment_screen" "$FILE" || {
  echo "WARN: payment success hook not patched. Need inspect App.tsx manually."
}

grep -q "session_started_from_welcome" "$FILE" || {
  echo "WARN: start session hook not patched. Need inspect App.tsx manually."
}

echo ""
echo "Relevant App lines:"
grep -n "useSessionLifecycle\\|startBoothSession\\|transitionBoothSession\\|cancelBoothSession\\|handleStartSession\\|handlePaymentSuccess\\|payment_confirmed_from_payment_screen\\|session_started_from_welcome" "$FILE" || true

echo ""
echo "Phase 8E1B1 completed."
