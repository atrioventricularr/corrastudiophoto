#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E3C2 - Auto Sync Session Lifecycle"
echo "========================================"

FILE="apps/booth-ui/src/sessions/SessionLifecycleProvider.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: SessionLifecycleProvider.tsx not found. Run 8E1A first."
  exit 1
}

[ -f "apps/booth-ui/src/sessions/supabase-session-lifecycle-sync.ts" ] || {
  echo "ERROR: sync helper not found. Run 8E3C1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/sessions/SessionLifecycleProvider.tsx")
text = path.read_text()

# 1. Add import
if "recordBoothSessionLifecycle" not in text:
    text = text.replace(
        """import type {
  CorraBoothSession,""",
        """import {
  isSessionLifecycleSyncConfigured,
  recordBoothSessionLifecycle,
} from './supabase-session-lifecycle-sync';
import type {
  CorraBoothSession,"""
    )

# 2. Add auto sync effect after lifecycleEvents save effect.
marker = """  useEffect(() => {
    saveLifecycleEvents(lifecycleEvents);
  }, [lifecycleEvents]);"""

patch = """  useEffect(() => {
    saveLifecycleEvents(lifecycleEvents);
  }, [lifecycleEvents]);

  useEffect(() => {
    if (!currentSession) {
      return;
    }

    if (!isSessionLifecycleSyncConfigured()) {
      return;
    }

    const currentSessionEvents = lifecycleEvents.filter(
      (event) => event.sessionId === currentSession.id,
    );

    const timer = window.setTimeout(() => {
      void recordBoothSessionLifecycle({
        session: currentSession,
        events: currentSessionEvents,
      }).then((result) => {
        if (!result.ok) {
          console.warn(
            '[Corra] Failed to sync session lifecycle:',
            result.error,
          );
        }
      });
    }, 700);

    return () => {
      window.clearTimeout(timer);
    };
  }, [currentSession, lifecycleEvents]);"""

if "Failed to sync session lifecycle" not in text:
    if marker not in text:
        raise SystemExit("Could not find lifecycleEvents save effect marker.")
    text = text.replace(marker, patch)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "recordBoothSessionLifecycle" "$FILE" || {
  echo "ERROR: recordBoothSessionLifecycle import/usage missing."
  exit 1
}

grep -q "Failed to sync session lifecycle" "$FILE" || {
  echo "ERROR: auto sync effect missing."
  exit 1
}

echo ""
echo "Relevant sync lines:"
grep -n "recordBoothSessionLifecycle\\|isSessionLifecycleSyncConfigured\\|Failed to sync session lifecycle" "$FILE" || true

echo ""
echo "Phase 8E3C2 completed."
