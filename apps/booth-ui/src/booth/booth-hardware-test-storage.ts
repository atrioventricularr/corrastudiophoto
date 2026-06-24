import type {
  BoothHardwareTestRecord,
  BoothHardwareTestStatus,
} from './booth-hardware-types';

const HARDWARE_TEST_KEY = 'corra.booth.hardware.tests.v1';

function makeId(label: string) {
  return `hardware-test-${label.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
}

export function loadBoothHardwareTestRecords(): BoothHardwareTestRecord[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(HARDWARE_TEST_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed.filter((record) => record && typeof record.id === 'string');
  } catch {
    return [];
  }
}

export function saveBoothHardwareTestRecords(records: BoothHardwareTestRecord[]) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(HARDWARE_TEST_KEY, JSON.stringify(records));
}

export function upsertBoothHardwareTestRecord(input: {
  label: string;
  status: BoothHardwareTestStatus;
  message?: string;
}) {
  const records = loadBoothHardwareTestRecords();
  const id = makeId(input.label);
  const nextRecord: BoothHardwareTestRecord = {
    id,
    label: input.label,
    status: input.status,
    message: input.message,
    updatedAt: new Date().toISOString(),
  };

  const nextRecords = [
    ...records.filter((record) => record.id !== id),
    nextRecord,
  ];

  saveBoothHardwareTestRecords(nextRecords);
  return nextRecord;
}

export function clearBoothHardwareTestRecords() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(HARDWARE_TEST_KEY);
}
