import type {
  BoothProductionAuditSummary,
  BoothProductionSecurityItem,
  BoothProductionSecurityStatus,
} from './booth-production-security-types';

const KEY = 'corra.booth.production.security.v1';

export const REQUIRED_PRODUCTION_SECURITY_ITEMS = [
  'License activation configured',
  'Payment provider configured',
  'Cloud upload configured',
  'Disk persistence configured',
  'Hardware diagnostics passed',
  'Kiosk controls tested',
  'Release candidate generated',
  'Secrets not stored in frontend',
];

function makeId(label: string) {
  return `prod-security-${label.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`;
}

export function loadProductionSecurityItems(): BoothProductionSecurityItem[] {
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

export function saveProductionSecurityItems(items: BoothProductionSecurityItem[]) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(KEY, JSON.stringify(items));
}

export function upsertProductionSecurityItem(input: {
  label: string;
  status: BoothProductionSecurityStatus;
  message?: string;
}) {
  const items = loadProductionSecurityItems();
  const nextItem: BoothProductionSecurityItem = {
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

  saveProductionSecurityItems(nextItems);
  return nextItem;
}

export function clearProductionSecurityItems() {
  if (typeof window === 'undefined') return;
  window.localStorage.removeItem(KEY);
}

export function summarizeProductionSecurityItems(
  items: BoothProductionSecurityItem[],
): BoothProductionAuditSummary {
  const summary: BoothProductionAuditSummary = {
    ready: false,
    passed: 0,
    warning: 0,
    failed: 0,
    untested: 0,
    total: REQUIRED_PRODUCTION_SECURITY_ITEMS.length,
  };

  const byLabel = new Map(items.map((item) => [item.label, item]));

  for (const label of REQUIRED_PRODUCTION_SECURITY_ITEMS) {
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
