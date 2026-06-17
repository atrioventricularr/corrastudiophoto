import type { CorraPaymentProviderId } from './types';

export type CorraPaymentTransactionStatus =
  | 'pending'
  | 'confirmed'
  | 'voucher_used'
  | 'cancelled'
  | 'failed';

export type CorraPaymentTransaction = {
  id: string;
  provider: CorraPaymentProviderId;
  status: CorraPaymentTransactionStatus;
  amountIdr: number;
  currency: 'IDR';
  merchantName: string;
  voucherCode?: string | null;
  confirmationCode?: string | null;
  failureReason?: string | null;
  cancelReason?: string | null;
  createdAt: string;
  updatedAt: string;
  confirmedAt?: string | null;
  cancelledAt?: string | null;
  metadata?: Record<string, unknown>;
};

export type CreatePaymentTransactionInput = {
  provider: CorraPaymentProviderId;
  amountIdr: number;
  merchantName: string;
  metadata?: Record<string, unknown>;
};

export type ConfirmPaymentTransactionInput = {
  status?: Extract<CorraPaymentTransactionStatus, 'confirmed' | 'voucher_used'>;
  voucherCode?: string | null;
  confirmationCode?: string | null;
  metadata?: Record<string, unknown>;
};

export type PaymentTransactionContextValue = {
  transactions: CorraPaymentTransaction[];
  currentTransaction: CorraPaymentTransaction | null;
  createPaymentTransaction: (
    input: CreatePaymentTransactionInput,
  ) => CorraPaymentTransaction;
  confirmPaymentTransaction: (
    transactionId: string,
    input?: ConfirmPaymentTransactionInput,
  ) => CorraPaymentTransaction | null;
  cancelPaymentTransaction: (
    transactionId: string,
    reason?: string,
  ) => CorraPaymentTransaction | null;
  failPaymentTransaction: (
    transactionId: string,
    reason?: string,
  ) => CorraPaymentTransaction | null;
  clearPaymentTransactions: () => void;
};
