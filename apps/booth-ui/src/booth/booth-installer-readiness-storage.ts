import type {
  BoothInstallerReadinessItem,
  BoothInstallerReadinessStatus,
  BoothInstallerReadinessSummary,
} from './booth-installer-readiness-types';

const KEY = 'corra.booth.installer.readiness.v1';

export const REQUIRED_INSTALLER_READINESS_ITEMS = [
  'Production bundle builds',
  'Electron main/preload present',
  'Windows launcher tested',
  'Electron Builder configured',
  'NSIS installer builds',
  'Portable build produced',
  'Code signing configured',
  'Installer smoke tested',
  'Kiosk startup tested',
  'Printer/camera tested on booth PC',
];

function makeId(label: string) {
  return `installer-readiness-${label.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
}

export function loadInstallerReadinessItems(): BoothInstallerReadinessItem[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed.filter((item) => item && typeof item.id === 'string');
  } catch {
    return [];
  }
}

export function saveInstallerReadinessItems(items: BoothInstallerReadinessItem[]) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(KEY, JSON.stringify(items));
}

export function upsertInstallerReadinessItem(input: {
  label: string;
  status: BoothInstallerReadinessStatus;
  message?: string;
}) {
  const items = loadInstallerReadinessItems();
  const nextItem: BoothInstallerReadinessItem = {
    id: makeId(input.label),
    label: input.label,
    status: input.status,
    message: input.message,
    updatedAt: new Date().toISOString(),
  };

  const nextItems = [
    ...items.filter((item) => item.id !== nextItem.id),
    nextItem,
  ];

  saveInstallerReadinessItems(nextItems);
  return nextItem;
}

export function clearInstallerReadinessItems() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(KEY);
}

export function summarizeInstallerReadiness(
  items: BoothInstallerReadinessItem[],
): BoothInstallerReadinessSummary {
  const summary: BoothInstallerReadinessSummary = {
    ready: false,
    passed: 0,
    warning: 0,
    failed: 0,
    untested: 0,
    total: REQUIRED_INSTALLER_READINESS_ITEMS.length,
  };

  const byLabel = new Map(items.map((item) => [item.label, item]));

  for (const label of REQUIRED_INSTALLER_READINESS_ITEMS) {
    const item = byLabel.get(label);

    if (!item) {
      summary.untested += 1;
      continue;
    }

    if (item.status === 'passed') summary.passed += 1;
    if (item.status === 'warning') summary.warning += 1;
    if (item.status === 'failed') summary.failed += 1;
    if (item.status === 'untested') summary.untested += 1;
  }

  summary.ready = summary.failed === 0 && summary.untested === 0;
  return summary;
}
