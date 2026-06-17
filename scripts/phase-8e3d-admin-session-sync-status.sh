#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E3D - Admin Session Sync Status"
echo "========================================"

TYPES_FILE="apps/booth-ui/src/sessions/types.ts"
PROVIDER_FILE="apps/booth-ui/src/sessions/SessionLifecycleProvider.tsx"
PANEL_FILE="apps/booth-ui/src/components/admin/SessionLifecyclePanel.tsx"

[ -f "$TYPES_FILE" ] || {
  echo "ERROR: types.ts not found. Run 8E1A first."
  exit 1
}

[ -f "$PROVIDER_FILE" ] || {
  echo "ERROR: SessionLifecycleProvider.tsx not found. Run 8E1A first."
  exit 1
}

[ -f "$PANEL_FILE" ] || {
  echo "ERROR: SessionLifecyclePanel.tsx not found. Run 8E2 first."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

# =========================
# 1. Patch types.ts
# =========================
types_path = Path("apps/booth-ui/src/sessions/types.ts")
text = types_path.read_text()

if "SessionLifecycleSyncStatus" not in text:
    text = text.replace(
        """export type CorraSessionLifecycleEvent = {""",
        """export type SessionLifecycleSyncStatus =
  | 'idle'
  | 'skipped'
  | 'syncing'
  | 'synced'
  | 'failed';

export type CorraSessionLifecycleEvent = {"""
    )

if "syncCurrentSession" not in text:
    text = text.replace(
        """  clearSessionHistory: () => void;""",
        """  syncStatus: SessionLifecycleSyncStatus;
  lastSyncedAt: string | null;
  syncError: string | null;
  syncCurrentSession: () => Promise<void>;
  clearSessionHistory: () => void;"""
    )

types_path.write_text(text)
print("PATCH file:", types_path)

# =========================
# 2. Patch Provider
# =========================
provider_path = Path("apps/booth-ui/src/sessions/SessionLifecycleProvider.tsx")
text = provider_path.read_text()

# Ensure sync helper import exists
if "recordBoothSessionLifecycle" not in text:
    text = text.replace(
        """import {
  clearLocalSessionLifecycle,""",
        """import {
  isSessionLifecycleSyncConfigured,
  recordBoothSessionLifecycle,
} from './supabase-session-lifecycle-sync';
import {
  clearLocalSessionLifecycle,"""
    )

# Ensure sync status type import exists
if "SessionLifecycleSyncStatus" not in text:
    text = text.replace(
        """  SessionLifecycleContextValue,""",
        """  SessionLifecycleContextValue,
  SessionLifecycleSyncStatus,"""
    )

# Add sync states
state_marker = """  const [lifecycleEvents, setLifecycleEvents] = useState<
    CorraSessionLifecycleEvent[]
  >(() => loadLifecycleEvents());"""

state_patch = """  const [lifecycleEvents, setLifecycleEvents] = useState<
    CorraSessionLifecycleEvent[]
  >(() => loadLifecycleEvents());
  const [syncStatus, setSyncStatus] =
    useState<SessionLifecycleSyncStatus>('idle');
  const [lastSyncedAt, setLastSyncedAt] = useState<string | null>(null);
  const [syncError, setSyncError] = useState<string | null>(null);"""

if state_marker in text and "setSyncStatus" not in text:
    text = text.replace(state_marker, state_patch)

# Remove old direct auto sync effect from 8E3C2 if exists
text = re.sub(
    r"""
  useEffect\(\(\) => \{
    if \(!currentSession\) \{
      return;
    \}

    if \(!isSessionLifecycleSyncConfigured\(\)\) \{
      return;
    \}

    const currentSessionEvents = lifecycleEvents\.filter\(
      \(event\) => event\.sessionId === currentSession\.id,
    \);

    const timer = window\.setTimeout\(\(\) => \{
      void recordBoothSessionLifecycle\(\{
        session: currentSession,
        events: currentSessionEvents,
      \}\)\.then\(\(result\) => \{
        if \(!result\.ok\) \{
          console\.warn\(
            '\[Corra\] Failed to sync session lifecycle:',
            result\.error,
          \);
        \}
      \}\);
    \}, 700\);

    return \(\) => \{
      window\.clearTimeout\(timer\);
    \};
  \}, \[currentSession, lifecycleEvents\]\);

""",
    "\n",
    text,
    flags=re.VERBOSE,
)

# Add syncCurrentSession callback before startBoothSession
if "session_lifecycle_manual_sync" not in text:
    marker = "  const startBoothSession = useCallback("
    sync_block = """  const syncCurrentSession = useCallback(async () => {
    if (!currentSession) {
      setSyncStatus('skipped');
      setSyncError('No active session to sync.');
      return;
    }

    if (!isSessionLifecycleSyncConfigured()) {
      setSyncStatus('skipped');
      setSyncError(
        'Session lifecycle sync is not configured. Check .env.local.',
      );
      return;
    }

    const currentSessionEvents = lifecycleEvents.filter(
      (event) => event.sessionId === currentSession.id,
    );

    setSyncStatus('syncing');
    setSyncError(null);

    const result = await recordBoothSessionLifecycle({
      session: currentSession,
      events: currentSessionEvents,
    });

    if (!result.ok) {
      setSyncStatus('failed');
      setSyncError(result.error || 'Failed to sync session lifecycle.');
      console.warn(
        '[Corra] Failed to sync session lifecycle:',
        result.error,
      );
      return;
    }

    setSyncStatus('synced');
    setLastSyncedAt(result.syncedAt || new Date().toISOString());
    setSyncError(null);
  }, [currentSession, lifecycleEvents]);

  useEffect(() => {
    if (!currentSession) {
      return;
    }

    const timer = window.setTimeout(() => {
      void syncCurrentSession();
    }, 900);

    return () => {
      window.clearTimeout(timer);
    };
  }, [currentSession, lifecycleEvents, syncCurrentSession]);

  // session_lifecycle_manual_sync

"""
    if marker not in text:
      raise SystemExit("Could not find startBoothSession marker.")
    text = text.replace(marker, sync_block + marker)

# Add fields to context value
if "syncStatus," not in text.split("const value = useMemo", 1)[-1]:
    text = text.replace(
        """      currentSession,
      sessionHistory,
      lifecycleEvents,
      startBoothSession,""",
        """      currentSession,
      sessionHistory,
      lifecycleEvents,
      syncStatus,
      lastSyncedAt,
      syncError,
      syncCurrentSession,
      startBoothSession,"""
    )

# Add fields to dependency array
if "syncCurrentSession," not in text.split("const value = useMemo", 1)[-1]:
    text = text.replace(
        """    currentSession,
    sessionHistory,
    lifecycleEvents,
    startBoothSession,""",
        """    currentSession,
    sessionHistory,
    lifecycleEvents,
    syncStatus,
    lastSyncedAt,
    syncError,
    syncCurrentSession,
    startBoothSession,"""
    )

provider_path.write_text(text)
print("PATCH file:", provider_path)

# =========================
# 3. Patch Admin Panel
# =========================
panel_path = Path("apps/booth-ui/src/components/admin/SessionLifecyclePanel.tsx")
text = panel_path.read_text()

if "getSyncStatusLabelClass" not in text:
    text = text.replace(
        """export function SessionLifecyclePanel() {""",
        """function getSyncStatusLabelClass(status?: string | null): string {
  if (status === 'synced') return 'bg-green-100 text-green-800';
  if (status === 'syncing') return 'bg-yellow-100 text-yellow-800';
  if (status === 'failed') return 'bg-red-100 text-red-800';
  if (status === 'skipped') return 'bg-slate-100 text-slate-700';

  return 'bg-blue-100 text-blue-800';
}

export function SessionLifecyclePanel() {"""
    )

old_destructure = """  const {
    currentSession,
    sessionHistory,
    lifecycleEvents,
    clearSessionHistory,
  } = useSessionLifecycle();"""

new_destructure = """  const {
    currentSession,
    sessionHistory,
    lifecycleEvents,
    syncStatus,
    lastSyncedAt,
    syncError,
    syncCurrentSession,
    clearSessionHistory,
  } = useSessionLifecycle();"""

if old_destructure in text:
    text = text.replace(old_destructure, new_destructure)

# Add sync summary under description
desc_marker = """          <p className="mt-1 text-xs font-semibold text-slate-500">
            Pantau status session dari payment sampai hasil foto delivered.
          </p>"""

sync_summary = """          <p className="mt-1 text-xs font-semibold text-slate-500">
            Pantau status session dari payment sampai hasil foto delivered.
          </p>

          <div className="mt-3 flex flex-wrap items-center gap-2">
            <span
              className={`rounded-full px-3 py-1 text-[10px] font-black uppercase tracking-wider ${getSyncStatusLabelClass(
                syncStatus,
              )}`}
            >
              Sync: {syncStatus}
            </span>

            <span className="text-[10px] font-bold text-slate-400">
              Last sync: {formatDate(lastSyncedAt)}
            </span>
          </div>

          {syncError && (
            <p className="mt-2 rounded-xl bg-red-50 px-3 py-2 text-xs font-bold text-red-700">
              {syncError}
            </p>
          )}"""

if desc_marker in text and "Sync: {syncStatus}" not in text:
    text = text.replace(desc_marker, sync_summary)

# Add Sync Now button before Clear
button_marker = """          <button
            type="button"
            onClick={clearSessionHistory}
            className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-xs font-black text-red-700"
          >
            Clear
          </button>"""

button_patch = """          <button
            type="button"
            onClick={() => void syncCurrentSession()}
            disabled={!currentSession || syncStatus === 'syncing'}
            className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-2 text-xs font-black text-blue-700 disabled:opacity-50"
          >
            {syncStatus === 'syncing' ? 'Syncing...' : 'Sync Now'}
          </button>

          <button
            type="button"
            onClick={clearSessionHistory}
            className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-xs font-black text-red-700"
          >
            Clear
          </button>"""

if button_marker in text and "Sync Now" not in text:
    text = text.replace(button_marker, button_patch)

panel_path.write_text(text)
print("PATCH file:", panel_path)
PY

echo ""
echo "Verifying..."

grep -q "SessionLifecycleSyncStatus" "$TYPES_FILE" || {
  echo "ERROR: SessionLifecycleSyncStatus missing in types."
  exit 1
}

grep -q "syncCurrentSession" "$PROVIDER_FILE" || {
  echo "ERROR: syncCurrentSession missing in provider."
  exit 1
}

grep -q "Sync Now" "$PANEL_FILE" || {
  echo "ERROR: Sync Now button missing in admin panel."
  exit 1
}

grep -q "Sync: {syncStatus}" "$PANEL_FILE" || {
  echo "ERROR: sync status badge missing in admin panel."
  exit 1
}

echo ""
echo "Relevant provider lines:"
grep -n "syncStatus\\|lastSyncedAt\\|syncError\\|syncCurrentSession\\|recordBoothSessionLifecycle" "$PROVIDER_FILE" || true

echo ""
echo "Relevant panel lines:"
grep -n "Sync: {syncStatus}\\|Sync Now\\|syncError\\|lastSyncedAt" "$PANEL_FILE" || true

echo ""
echo "Phase 8E3D completed."
