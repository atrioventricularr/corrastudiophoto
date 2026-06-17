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
