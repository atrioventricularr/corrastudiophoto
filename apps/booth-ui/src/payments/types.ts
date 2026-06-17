export type CorraPaymentProviderId =
  | 'STATIC_QRIS'
  | 'DOKU_QRIS'
  | 'MANUAL_CASH'
  | 'MAYAR_CHECKOUT';

export type CorraPaymentEnvironment = 'sandbox' | 'production';

export type CorraPaymentConfig = {
  provider: CorraPaymentProviderId;
  priceIdr: number;
  currency: 'IDR';
  merchantName: string;
  requireOperatorConfirmation: boolean;
  staticQris: {
    imageUrl: string;
    merchantName: string;
    notes: string;
  };
  doku: {
    environment: CorraPaymentEnvironment;
    clientId: string;
    merchantId: string;
    isCredentialConfigured: boolean;
  };
  mayarCheckout: {
    productId: string;
    checkoutUrl: string;
    isConfigured: boolean;
  };
  manualCash: {
    instructions: string;
  };
  updatedAt: string | null;
};

export type CorraPaymentSettingsContextValue = {
  paymentConfig: CorraPaymentConfig;
  setPaymentConfig: (nextConfig: CorraPaymentConfig) => void;
  updatePaymentConfig: (patch: Partial<CorraPaymentConfig>) => void;
  resetPaymentConfig: () => void;
};
