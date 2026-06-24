import type {
  BoothReleaseCheckCategory,
  BoothReleaseCheckRecord,
  BoothReleaseCheckStatus,
  BoothReleaseSummary,
} from './booth-release-types';

const RELEASE_CHECKS_KEY = 'corra.booth.release.checks.v1';

export const REQUIRED_RELEASE_CHECKS = [
  'TypeScript clean',
  'Booth UI build',
  'Electron runtime opens',
  'License activation works',
  'Payment method configured',
  'Cloud upload configured',
  'Disk persistence works',
  'Printer detected',
  'Camera detected',
  'Kiosk mode tested',
  'Admin unlock tested',
  'Final delivery tested',
];

function makeId(label: string) {
  return `release-check-${label.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
}

export function loadBoothReleaseCheckRecords(): BoothReleaseCheckRecord[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(RELEASE_CHECKS_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((record) => record && typeof record.id === 'string');
  } catch {
    return [];
  }
}

export function saveBoothReleaseCheckRecords(records: BoothReleaseCheckRecord[]) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(RELEASE_CHECKS_KEY, JSON.stringify(records));
}

export function upsertBoothReleaseCheckRecord(input: {
  label: string;
  category: BoothReleaseCheckCategory;
  status: BoothReleaseCheckStatus;
  message?: string;
}) {
  const records = loadBoothReleaseCheckRecords();
  const id = makeId(input.label);
  const nextRecord: BoothReleaseCheckRecord = {
    id,
    label: input.label,
    category: input.category,
    status: input.status,
    message: input.message,
    updatedAt: new Date().toISOString(),
  };

  const nextRecords = [...records.filter((record) => record.id !== id), nextRecord];
  saveBoothReleaseCheckRecords(nextRecords);
  return nextRecord;
}

export function clearBoothReleaseCheckRecords() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(RELEASE_CHECKS_KEY);
}

export function summarizeBoothReleaseReadiness(
  records: BoothReleaseCheckRecord[],
): BoothReleaseSummary {
  const passedLabels = new Set(
    records.filter((record) => record.status === 'passed').map((record) => record.label),
  );
  const missingLabels = REQUIRED_RELEASE_CHECKS.filter((label) => !passedLabels.has(label));

  return {
    required: REQUIRED_RELEASE_CHECKS.length,
    passed: REQUIRED_RELEASE_CHECKS.length - missingLabels.length,
    warnings: records.filter((record) => record.status === 'warning').length,
    failed: records.filter((record) => record.status === 'failed').length,
    ready: missingLabels.length === 0,
    missingLabels,
  };
}
