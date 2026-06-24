import type {
  CreateRealPaymentIntentInput,
  RealPaymentIntent,
} from './real-payment-types';
import { createClientId } from './real-payment-storage';
import { createMayarCheckoutIntent } from './mayar-payment-api';

export async function createRealPaymentIntent(
  input: CreateRealPaymentIntentInput,
): Promise<RealPaymentIntent> {
  if (input.provider === 'MAYAR_CHECKOUT') {
    return createMayarCheckoutIntent(input);
  }

  const now = new Date().toISOString();

  if (input.provider === 'MANUAL_CASH') {
    return {
      id: createClientId('cash'),
      sessionId: input.sessionId,
      provider: 'MANUAL_CASH',
      status: 'pending',
      amount: input.amount,
      currency: input.currency || 'IDR',
      description: input.description || 'Manual cash payment',
      customer: input.customer,
      createdAt: now,
      updatedAt: now,
    };
  }

  if (input.provider === 'STATIC_QRIS') {
    return {
      id: createClientId('static-qris'),
      sessionId: input.sessionId,
      provider: 'STATIC_QRIS',
      status: 'pending',
      amount: input.amount,
      currency: input.currency || 'IDR',
      description: input.description || 'Static QRIS payment',
      customer: input.customer,
      createdAt: now,
      updatedAt: now,
    };
  }

  return {
    id: createClientId('doku'),
    sessionId: input.sessionId,
    provider: 'DOKU_QRIS',
    status: 'pending',
    amount: input.amount,
    currency: input.currency || 'IDR',
    description: input.description || 'DOKU QRIS payment',
    customer: input.customer,
    createdAt: now,
    updatedAt: now,
    error: 'DOKU runtime bridge should reuse existing 8D APIs in the next hardening pass.',
  };
}
