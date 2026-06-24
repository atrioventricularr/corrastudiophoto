import type { PaymentRuntimeSummary, RealPaymentIntent } from './real-payment-types';

const INTENTS_KEY = 'corra.real.payment.intents.v1';

export function createClientId(prefix = 'payment') {
  if (typeof window !== 'undefined' && window.crypto?.randomUUID) {
    return `${prefix}-${window.crypto.randomUUID()}`;
  }

  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function loadRealPaymentIntents(): RealPaymentIntent[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(INTENTS_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed.filter((item) => item && typeof item.id === 'string');
  } catch {
    return [];
  }
}

export function saveRealPaymentIntents(intents: RealPaymentIntent[]) {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(INTENTS_KEY, JSON.stringify(intents.slice(-300)));
}

export function upsertRealPaymentIntent(intent: RealPaymentIntent) {
  const intents = loadRealPaymentIntents();
  const index = intents.findIndex((candidate) => candidate.id === intent.id);
  const next = [...intents];

  if (index >= 0) next[index] = intent;
  else next.push(intent);

  saveRealPaymentIntents(next);
  return next;
}

export function summarizeRealPaymentIntents(
  intents: RealPaymentIntent[],
): PaymentRuntimeSummary {
  return intents.reduce(
    (acc, intent) => {
      acc.total += 1;
      if (intent.status === 'pending' || intent.status === 'created') acc.pending += 1;
      if (intent.status === 'paid') acc.paid += 1;
      if (intent.status === 'failed' || intent.status === 'cancelled') acc.failed += 1;
      if (intent.status === 'expired') acc.expired += 1;
      return acc;
    },
    { total: 0, pending: 0, paid: 0, failed: 0, expired: 0 },
  );
}
