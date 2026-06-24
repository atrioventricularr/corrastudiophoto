import type {
  CreateRealPaymentIntentInput,
  RealPaymentIntent,
  RealPaymentIntentStatus,
} from './real-payment-types';
import { createClientId } from './real-payment-storage';

export type CreateMayarCheckoutResponse = {
  ok: boolean;
  provider?: 'MAYAR_CHECKOUT';
  sessionId?: string;
  amount?: number;
  currency?: string;
  status?: RealPaymentIntentStatus;
  providerOrderId?: string;
  providerReferenceId?: string;
  checkoutUrl?: string;
  expiresAt?: string;
  raw?: unknown;
  error?: string;
};

export type CheckMayarStatusResponse = {
  ok: boolean;
  provider?: 'MAYAR_CHECKOUT';
  status?: RealPaymentIntentStatus;
  paidAt?: string | null;
  providerOrderId?: string;
  providerReferenceId?: string;
  sessionId?: string;
  raw?: unknown;
  error?: string;
};

export function getCreateMayarCheckoutUrl() {
  return import.meta.env.VITE_CREATE_MAYAR_CHECKOUT_URL || '';
}

export function getCheckMayarTransactionStatusUrl() {
  return import.meta.env.VITE_CHECK_MAYAR_TRANSACTION_STATUS_URL || '';
}

export async function createMayarCheckoutIntent(
  input: CreateRealPaymentIntentInput,
): Promise<RealPaymentIntent> {
  const url = getCreateMayarCheckoutUrl();
  if (!url) throw new Error('VITE_CREATE_MAYAR_CHECKOUT_URL is not configured.');

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      sessionId: input.sessionId,
      amount: input.amount,
      currency: input.currency || 'IDR',
      description: input.description || 'Corra Booth Photo Session',
      customerName: input.customer?.name,
      customerEmail: input.customer?.email,
      customerPhone: input.customer?.phone,
      expiresInMinutes: 30,
    }),
  });

  const result = (await response.json()) as CreateMayarCheckoutResponse;
  if (!response.ok || !result.ok) throw new Error(result.error || 'Failed to create Mayar checkout.');

  const now = new Date().toISOString();

  return {
    id: createClientId('mayar'),
    sessionId: result.sessionId || input.sessionId,
    provider: 'MAYAR_CHECKOUT',
    status: result.status || 'pending',
    amount: result.amount || input.amount,
    currency: result.currency || input.currency || 'IDR',
    description: input.description || 'Corra Booth Photo Session',
    checkoutUrl: result.checkoutUrl,
    providerOrderId: result.providerOrderId,
    providerReferenceId: result.providerReferenceId,
    customer: input.customer,
    createdAt: now,
    updatedAt: now,
    expiresAt: result.expiresAt,
    raw: result.raw,
  };
}

export async function checkMayarIntentStatus(
  intent: RealPaymentIntent,
): Promise<RealPaymentIntent> {
  const url = getCheckMayarTransactionStatusUrl();
  if (!url) throw new Error('VITE_CHECK_MAYAR_TRANSACTION_STATUS_URL is not configured.');

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      providerOrderId: intent.providerOrderId,
      providerReferenceId: intent.providerReferenceId,
      sessionId: intent.sessionId,
    }),
  });

  const result = (await response.json()) as CheckMayarStatusResponse;
  if (!response.ok || !result.ok) throw new Error(result.error || 'Failed to check Mayar status.');

  return {
    ...intent,
    status: result.status || intent.status,
    paidAt: result.paidAt || intent.paidAt,
    updatedAt: new Date().toISOString(),
    raw: result.raw || intent.raw,
  };
}
