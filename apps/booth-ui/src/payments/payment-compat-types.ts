export type CorraPaymentProviderId =
  | 'STATIC_QRIS'
  | 'DOKU_QRIS'
  | 'MANUAL_CASH'
  | 'MAYAR_CHECKOUT';

export type CorraPaymentEnvironment = 'sandbox' | 'production';

export type CorraPaymentTransactionStatus =
  | 'pending'
  | 'waiting'
  | 'paid'
  | 'confirmed'
  | 'failed'
  | 'expired'
  | 'cancelled';

export type CorraPaymentTransaction = {
  id: string;
  sessionId?: string;
  providerId?: CorraPaymentProviderId;
  provider?: CorraPaymentProviderId;
  status: CorraPaymentTransactionStatus | string;
  amount?: number;
  currency?: string;
  customerName?: string;
  customerEmail?: string;
  externalId?: string;
  checkoutUrl?: string;
  qrString?: string;
  qrImageUrl?: string;
  syncStatus?: string;
  syncError?: string;
  createdAt?: string;
  updatedAt?: string;
  paidAt?: string;
};
