#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E4A - Export Session Report CSV"
echo "========================================"

mkdir -p apps/booth-ui/src/sessions

cat > apps/booth-ui/src/sessions/session-report-export.ts <<'TS'
import type {
  CorraBoothSession,
  CorraSessionLifecycleEvent,
} from './types';

function escapeCsv(value: unknown): string {
  if (value === null || value === undefined) return '';

  const stringValue =
    typeof value === 'object' ? JSON.stringify(value) : String(value);

  if (
    stringValue.includes(',') ||
    stringValue.includes('"') ||
    stringValue.includes('\n') ||
    stringValue.includes('\r')
  ) {
    return `"${stringValue.replace(/"/g, '""')}"`;
  }

  return stringValue;
}

function downloadCsv(filename: string, csvContent: string): void {
  if (typeof window === 'undefined') return;

  const blob = new Blob([csvContent], {
    type: 'text/csv;charset=utf-8;',
  });

  const url = window.URL.createObjectURL(blob);
  const anchor = document.createElement('a');

  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';

  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);

  window.URL.revokeObjectURL(url);
}

function createTimestampForFilename(): string {
  return new Date()
    .toISOString()
    .replace(/[:.]/g, '-')
    .replace('T', '_')
    .slice(0, 19);
}

export function exportSessionsCsv(sessions: CorraBoothSession[]): void {
  const headers = [
    'session_id',
    'status',
    'payment_transaction_id',
    'payment_confirmation_code',
    'voucher_code',
    'layout_id',
    'template_id',
    'capture_count',
    'final_asset_url',
    'gif_asset_url',
    'error_message',
    'created_at',
    'updated_at',
    'completed_at',
    'cancelled_at',
    'metadata',
  ];

  const rows = sessions.map((session) => [
    session.id,
    session.status,
    session.paymentTransactionId || '',
    session.paymentConfirmationCode || '',
    session.voucherCode || '',
    session.layoutId || '',
    session.templateId || '',
    session.captureCount || 0,
    session.finalAssetUrl || '',
    session.gifAssetUrl || '',
    session.errorMessage || '',
    session.createdAt,
    session.updatedAt,
    session.completedAt || '',
    session.cancelledAt || '',
    session.metadata || {},
  ]);

  const csv = [
    headers.map(escapeCsv).join(','),
    ...rows.map((row) => row.map(escapeCsv).join(',')),
  ].join('\n');

  downloadCsv(`corra-booth-sessions-${createTimestampForFilename()}.csv`, csv);
}

export function exportSessionEventsCsv(
  events: CorraSessionLifecycleEvent[],
): void {
  const headers = [
    'event_id',
    'session_id',
    'from_status',
    'to_status',
    'reason',
    'created_at',
    'metadata',
  ];

  const rows = events.map((event) => [
    event.id,
    event.sessionId,
    event.fromStatus || '',
    event.toStatus,
    event.reason || '',
    event.createdAt,
    event.metadata || {},
  ]);

  const csv = [
    headers.map(escapeCsv).join(','),
    ...rows.map((row) => row.map(escapeCsv).join(',')),
  ].join('\n');

  downloadCsv(
    `corra-booth-session-events-${createTimestampForFilename()}.csv`,
    csv,
  );
}
TS

grep -q "session-report-export" apps/booth-ui/src/sessions/index.ts || cat >> apps/booth-ui/src/sessions/index.ts <<'TS'
export * from './session-report-export';
TS

PANEL_FILE="apps/booth-ui/src/components/admin/SessionLifecyclePanel.tsx"

[ -f "$PANEL_FILE" ] || {
  echo "ERROR: SessionLifecyclePanel.tsx not found. Run 8E2 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/SessionLifecyclePanel.tsx")
text = path.read_text()

# Add import
if "exportSessionsCsv" not in text:
    text = text.replace(
        "import { useSessionLifecycle } from '../../sessions';",
        """import {
  exportSessionEventsCsv,
  exportSessionsCsv,
  useSessionLifecycle,
} from '../../sessions';"""
    )

# Add buttons before Sync Now button
marker = """          <button
            type="button"
            onClick={() => void syncCurrentSession()}
            disabled={!currentSession || syncStatus === 'syncing'}
            className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-2 text-xs font-black text-blue-700 disabled:opacity-50"
          >
            {syncStatus === 'syncing' ? 'Syncing...' : 'Sync Now'}
          </button>"""

patch = """          <button
            type="button"
            onClick={() => exportSessionsCsv(sessionHistory)}
            disabled={sessionHistory.length === 0}
            className="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-2 text-xs font-black text-emerald-700 disabled:opacity-50"
          >
            Export Sessions CSV
          </button>

          <button
            type="button"
            onClick={() => exportSessionEventsCsv(lifecycleEvents)}
            disabled={lifecycleEvents.length === 0}
            className="rounded-2xl border border-purple-200 bg-purple-50 px-4 py-2 text-xs font-black text-purple-700 disabled:opacity-50"
          >
            Export Events CSV
          </button>

          <button
            type="button"
            onClick={() => void syncCurrentSession()}
            disabled={!currentSession || syncStatus === 'syncing'}
            className="rounded-2xl border border-blue-200 bg-blue-50 px-4 py-2 text-xs font-black text-blue-700 disabled:opacity-50"
          >
            {syncStatus === 'syncing' ? 'Syncing...' : 'Sync Now'}
          </button>"""

if marker in text and "Export Sessions CSV" not in text:
    text = text.replace(marker, patch)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "exportSessionsCsv" apps/booth-ui/src/sessions/session-report-export.ts || {
  echo "ERROR: exportSessionsCsv missing."
  exit 1
}

grep -q "Export Sessions CSV" "$PANEL_FILE" || {
  echo "ERROR: Export Sessions CSV button missing."
  exit 1
}

grep -q "Export Events CSV" "$PANEL_FILE" || {
  echo "ERROR: Export Events CSV button missing."
  exit 1
}

echo ""
echo "Relevant panel lines:"
grep -n "Export Sessions CSV\\|Export Events CSV\\|exportSessionsCsv\\|exportSessionEventsCsv" "$PANEL_FILE" || true

echo ""
echo "Phase 8E4A completed."
