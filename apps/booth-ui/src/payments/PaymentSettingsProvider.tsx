import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { DEFAULT_CORRA_PAYMENT_CONFIG } from './default-payment-config';
import {
  clearLocalPaymentConfig,
  loadLocalPaymentConfig,
  saveLocalPaymentConfig,
} from './local-payment-config';
import type {
  CorraPaymentConfig,
  CorraPaymentSettingsContextValue,
} from './types';

const PaymentSettingsContext =
  createContext<CorraPaymentSettingsContextValue | null>(null);

type PaymentSettingsProviderProps = {
  children: ReactNode;
};

export function PaymentSettingsProvider({
  children,
}: PaymentSettingsProviderProps) {
  const [paymentConfig, setPaymentConfigState] = useState<CorraPaymentConfig>(
    () => loadLocalPaymentConfig(),
  );

  useEffect(() => {
    saveLocalPaymentConfig(paymentConfig);
  }, [paymentConfig]);

  const value = useMemo<CorraPaymentSettingsContextValue>(() => {
    return {
      paymentConfig,
      setPaymentConfig: setPaymentConfigState,
      updatePaymentConfig: (patch) => {
        setPaymentConfigState((current) => ({
          ...current,
          ...patch,
          staticQris: {
            ...current.staticQris,
            ...(patch.staticQris || {}),
          },
          doku: {
            ...current.doku,
            ...(patch.doku || {}),
          },
          mayarCheckout: {
            ...current.mayarCheckout,
            ...(patch.mayarCheckout || {}),
          },
          manualCash: {
            ...current.manualCash,
            ...(patch.manualCash || {}),
          },
        }));
      },
      resetPaymentConfig: () => {
        clearLocalPaymentConfig();
        setPaymentConfigState(DEFAULT_CORRA_PAYMENT_CONFIG);
      },
    };
  }, [paymentConfig]);

  return (
    <PaymentSettingsContext.Provider value={value}>
      {children}
    </PaymentSettingsContext.Provider>
  );
}

export function usePaymentSettings(): CorraPaymentSettingsContextValue {
  const context = useContext(PaymentSettingsContext);

  if (!context) {
    throw new Error('usePaymentSettings must be used inside PaymentSettingsProvider');
  }

  return context;
}
