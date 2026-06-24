#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/booth/booth-disk-storage.ts"

cat > "$FILE" <<'TS'
export type BoothDiskRecordKind =
  | 'raw_capture'
  | 'final_output'
  | 'print_ready'
  | 'export'
  | string;

export type BoothDiskRecord = {
  id: string;
  sessionId?: string;
  kind: BoothDiskRecordKind;
  filename?: string;
  filePath?: string;
  absolutePath?: string;
  relativePath?: string;
  sizeBytes?: number;
  createdAt?: string;
  updatedAt?: string;
  [key: string]: unknown;
};

const DISK_RECORDS_KEY = 'corra.booth.disk.records.v1';

function normalizeRecord(input: unknown, index: number): BoothDiskRecord | null {
  if (!input || typeof input !== 'object') return null;

  const record = input as Record<string, unknown>;

  return {
    ...record,
    id:
      typeof record.id === 'string'
        ? record.id
        : `disk-record-${index}-${Date.now()}`,
    kind:
      typeof record.kind === 'string'
        ? record.kind
        : 'export',
  } as BoothDiskRecord;
}

export function loadBoothDiskRecords(): BoothDiskRecord[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(DISK_RECORDS_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed
      .map((item, index) => normalizeRecord(item, index))
      .filter((item): item is BoothDiskRecord => Boolean(item));
  } catch {
    return [];
  }
}

export function saveBoothDiskRecords(records: BoothDiskRecord[]) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(DISK_RECORDS_KEY, JSON.stringify(records.slice(-500)));
}

export function addBoothDiskRecord(record: BoothDiskRecord) {
  const records = loadBoothDiskRecords();
  const nextRecords = [
    ...records.filter((item) => item.id !== record.id),
    {
      ...record,
      updatedAt: new Date().toISOString(),
      createdAt: record.createdAt || new Date().toISOString(),
    },
  ];

  saveBoothDiskRecords(nextRecords);
  return nextRecords;
}

export function removeBoothDiskRecord(recordId: string) {
  const records = loadBoothDiskRecords();
  const nextRecords = records.filter((record) => record.id !== recordId);
  saveBoothDiskRecords(nextRecords);
  return nextRecords;
}

export function clearBoothDiskRecords() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(DISK_RECORDS_KEY);
}
TS

grep -q "booth-disk-storage" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './booth-disk-storage';
TS

echo "Created $FILE"
