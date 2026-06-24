export type RealPaymentProvider =
  | 'STATIC_QRIS'
  | 'DOKU_QRIS'
  | 'MAYAR_CHECKOUT'
  | 'MANUAL_CASH';

export type RealPaymentIntentStatus =
  | 'idle'
  | 'created'
  | 'pending'
  | 'paid'
  | 'failed'
  | 'expired'
  | 'cancelled';

export type RealPaymentCustomer = {
  name?: string;
  email?: string;
  phone?: string;
};

export type RealPaymentIntent = {
  id: string;
  sessionId: string;
  provider: RealPaymentProvider;
  status: RealPaymentIntentStatus;
  amount: number;
  currency: string;
  description: string;
  checkoutUrl?: string;
  qrString?: string;
  qrImageUrl?: string;
  providerOrderId?: string;
  providerReferenceId?: string;
  customer?: RealPaymentCustomer;
  error?: string;
  createdAt: string;
  updatedAt: string;
  paidAt?: string;
  expiresAt?: string;
  raw?: unknown;
};

export type CreateRealPaymentIntentInput = {
  sessionId: string;
  provider: RealPaymentProvider;
  amount: number;
  currency?: string;
  description?: string;
  customer?: RealPaymentCustomer;
};

export type PaymentRuntimeSummary = {
  total: number;
  pending: number;
  paid: number;
  failed: number;
  expired: number;
};
