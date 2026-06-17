import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  clearLocalPaymentTransactions,
  loadLocalPaymentTransactions,
  saveLocalPaymentTransactions,
} from './local-payment-transactions';
import type {
  ConfirmPaymentTransactionInput,
  CorraPaymentTransaction,
  CreatePaymentTransactionInput,
  PaymentTransactionContextValue,
} from './transaction-types';

const PaymentTransactionContext =
  createContext<PaymentTransactionContextValue | null>(null);

type PaymentTransactionProviderProps = {
  children: ReactNode;
};

function createTransactionId(): string {
  const random =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID()
      : `txn-${Date.now()}-${Math.random().toString(16).slice(2)}`;

  return random.startsWith('txn-') ? random : `txn-${random}`;
}

function sortTransactions(
  transactions: CorraPaymentTransaction[],
): CorraPaymentTransaction[] {
  return [...transactions].sort((a, b) => {
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });
}

export function PaymentTransactionProvider({
  children,
}: PaymentTransactionProviderProps) {
  const [transactions, setTransactions] = useState<CorraPaymentTransaction[]>(
    () => sortTransactions(loadLocalPaymentTransactions()),
  );
  const [currentTransaction, setCurrentTransaction] =
    useState<CorraPaymentTransaction | null>(null);

  useEffect(() => {
    saveLocalPaymentTransactions(transactions.slice(0, 100));
  }, [transactions]);

  const createPaymentTransaction = useCallback(
    (input: CreatePaymentTransactionInput) => {
      const now = new Date().toISOString();

      const transaction: CorraPaymentTransaction = {
        id: createTransactionId(),
        provider: input.provider,
        status: 'pending',
        amountIdr: input.amountIdr,
        currency: 'IDR',
        merchantName: input.merchantName,
        voucherCode: null,
        confirmationCode: null,
        failureReason: null,
        cancelReason: null,
        createdAt: now,
        updatedAt: now,
        confirmedAt: null,
        cancelledAt: null,
        metadata: input.metadata || {},
      };

      setTransactions((current) => sortTransactions([transaction, ...current]));
      setCurrentTransaction(transaction);

      return transaction;
    },
    [],
  );

  const updateTransaction = useCallback(
    (
      transactionId: string,
      updater: (transaction: CorraPaymentTransaction) => CorraPaymentTransaction,
    ) => {
      let updatedTransaction: CorraPaymentTransaction | null = null;

      setTransactions((current) => {
        const next = current.map((transaction) => {
          if (transaction.id !== transactionId) {
            return transaction;
          }

          updatedTransaction = updater(transaction);

          return updatedTransaction;
        });

        return sortTransactions(next);
      });

      if (updatedTransaction) {
        setCurrentTransaction(updatedTransaction);
      }

      return updatedTransaction;
    },
    [],
  );

  const confirmPaymentTransaction = useCallback(
    (
      transactionId: string,
      input: ConfirmPaymentTransactionInput = {},
    ) => {
      return updateTransaction(transactionId, (transaction) => {
        const now = new Date().toISOString();

        return {
          ...transaction,
          status: input.status || 'confirmed',
          voucherCode: input.voucherCode ?? transaction.voucherCode ?? null,
          confirmationCode:
            input.confirmationCode ?? transaction.confirmationCode ?? null,
          metadata: {
            ...(transaction.metadata || {}),
            ...(input.metadata || {}),
          },
          confirmedAt: now,
          updatedAt: now,
        };
      });
    },
    [updateTransaction],
  );

  const cancelPaymentTransaction = useCallback(
    (transactionId: string, reason = 'cancelled') => {
      return updateTransaction(transactionId, (transaction) => {
        if (transaction.status !== 'pending') {
          return transaction;
        }

        const now = new Date().toISOString();

        return {
          ...transaction,
          status: 'cancelled',
          cancelReason: reason,
          cancelledAt: now,
          updatedAt: now,
        };
      });
    },
    [updateTransaction],
  );

  const failPaymentTransaction = useCallback(
    (transactionId: string, reason = 'failed') => {
      return updateTransaction(transactionId, (transaction) => {
        const now = new Date().toISOString();

        return {
          ...transaction,
          status: 'failed',
          failureReason: reason,
          updatedAt: now,
        };
      });
    },
    [updateTransaction],
  );

  const clearPaymentTransactions = useCallback(() => {
    clearLocalPaymentTransactions();
    setTransactions([]);
    setCurrentTransaction(null);
  }, []);

  const value = useMemo<PaymentTransactionContextValue>(() => {
    return {
      transactions,
      currentTransaction,
      createPaymentTransaction,
      confirmPaymentTransaction,
      cancelPaymentTransaction,
      failPaymentTransaction,
      clearPaymentTransactions,
    };
  }, [
    transactions,
    currentTransaction,
    createPaymentTransaction,
    confirmPaymentTransaction,
    cancelPaymentTransaction,
    failPaymentTransaction,
    clearPaymentTransactions,
  ]);

  return (
    <PaymentTransactionContext.Provider value={value}>
      {children}
    </PaymentTransactionContext.Provider>
  );
}

export function usePaymentTransactions(): PaymentTransactionContextValue {
  const context = useContext(PaymentTransactionContext);

  if (!context) {
    throw new Error(
      'usePaymentTransactions must be used inside PaymentTransactionProvider',
    );
  }

  return context;
}
