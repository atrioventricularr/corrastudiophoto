import type { BoothDiskFileRecord } from './booth-disk-persistence-types';

const RECORDS_KEY = 'corra.booth.disk.persistence.records.v1';

export function loadBoothDiskRecords(): BoothDiskFileRecord[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(RECORDS_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed.filter((record) => record && typeof record.id === 'string');
  } catch {
    return [];
  }
}

export function saveBoothDiskRecords(records: BoothDiskFileRecord[]) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(RECORDS_KEY, JSON.stringify(records.slice(-1000)));
}

export function appendBoothDiskRecord(record: BoothDiskFileRecord) {
  const records = loadBoothDiskRecords();
  const nextRecords = [...records.filter((item) => item.id !== record.id), record];
  saveBoothDiskRecords(nextRecords);
  return nextRecords;
}

export function clearBoothDiskRecords() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(RECORDS_KEY);
}

export function removeBoothDiskRecordByRelativePath(relativePath: string) {
  const records = loadBoothDiskRecords();
  const nextRecords = records.filter((record) => record.relativePath !== relativePath);
  saveBoothDiskRecords(nextRecords);
  return nextRecords;
}
