import type { CorraPaymentConfig } from './types';

export const DEFAULT_CORRA_PAYMENT_CONFIG: CorraPaymentConfig = {
  provider: 'STATIC_QRIS',
  priceIdr: 35000,
  currency: 'IDR',
  merchantName: 'Corra Studio',
  requireOperatorConfirmation: true,
  staticQris: {
    imageUrl: '',
    merchantName: 'Corra Studio',
    notes: 'Scan QRIS, lalu tunjukkan bukti pembayaran ke operator.',
  },
  doku: {
    environment: 'sandbox',
    clientId: '',
    merchantId: '',
    isCredentialConfigured: false,
  },
  mayarCheckout: {
    productId: '',
    checkoutUrl: '',
    isConfigured: false,
  },
  manualCash: {
    instructions: 'Bayar langsung ke operator sebelum sesi foto dimulai.',
  },
  updatedAt: null,
};
