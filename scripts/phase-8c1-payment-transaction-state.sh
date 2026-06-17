#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 8C1 Payment Transaction State"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

write_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
  echo "WRITE file: $file_path"
}

[ -f "apps/booth-ui/src/components/PaymentScreen.tsx" ] || fail "PaymentScreen.tsx not found."
[ -f "apps/booth-ui/src/components/AdminPanel.tsx" ] || fail "AdminPanel.tsx not found."
[ -f "apps/booth-ui/src/payments/index.ts" ] || fail "payments module not found. Run 8A1 first."
[ -f "apps/booth-ui/src/main.tsx" ] || fail "main.tsx not found."

echo ""
echo "Writing payment transaction types..."

write_file "apps/booth-ui/src/payments/transaction-types.ts" <<'TS'
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
TS

echo ""
echo "Writing local transaction storage..."

write_file "apps/booth-ui/src/payments/local-payment-transactions.ts" <<'TS'
import type { CorraPaymentTransaction } from './transaction-types';

const STORAGE_KEY = 'corra.paymentTransactions.v1';

export function loadLocalPaymentTransactions(): CorraPaymentTransaction[] {
  if (typeof window === 'undefined') {
    return [];
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return [];
    }

    const parsed = JSON.parse(raw);

    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveLocalPaymentTransactions(
  transactions: CorraPaymentTransaction[],
): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
}

export function clearLocalPaymentTransactions(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(STORAGE_KEY);
}
TS

echo ""
echo "Writing PaymentTransactionProvider..."

write_file "apps/booth-ui/src/payments/PaymentTransactionProvider.tsx" <<'TSX'
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
TSX

echo ""
echo "Exporting transaction modules..."

cat >> apps/booth-ui/src/payments/index.ts <<'TS'
export * from './transaction-types';
export * from './local-payment-transactions';
export * from './PaymentTransactionProvider';
TS

echo ""
echo "Patching main.tsx provider wrapper..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/main.tsx")
text = path.read_text()

text = text.replace(
    "import { PaymentSettingsProvider } from './payments';",
    "import { PaymentSettingsProvider, PaymentTransactionProvider } from './payments';"
)

if "<PaymentTransactionProvider>" not in text:
    text = text.replace(
        """<PaymentSettingsProvider>
        <ThemedBackground />
        <App />
      </PaymentSettingsProvider>""",
        """<PaymentSettingsProvider>
        <PaymentTransactionProvider>
          <ThemedBackground />
          <App />
        </PaymentTransactionProvider>
      </PaymentSettingsProvider>"""
    )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/main.tsx")
PY

echo ""
echo "Patching PaymentScreen transaction flow..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/PaymentScreen.tsx")
text = path.read_text()

text = text.replace(
    "import React, { useMemo, useState } from 'react';",
    "import React, { useEffect, useMemo, useRef, useState } from 'react';"
)

text = text.replace(
    "import { usePaymentSettings } from '../payments';",
    "import { usePaymentSettings, usePaymentTransactions } from '../payments';"
)

if "transactionIdRef" not in text:
    text = text.replace(
        "  const { paymentConfig } = usePaymentSettings();",
        """  const { paymentConfig } = usePaymentSettings();
  const {
    createPaymentTransaction,
    confirmPaymentTransaction,
    cancelPaymentTransaction,
  } = usePaymentTransactions();
  const transactionIdRef = useRef<string | null>(null);"""
    )

effect_block = """
  useEffect(() => {
    if (transactionIdRef.current) {
      return;
    }

    const transaction = createPaymentTransaction({
      provider: paymentConfig.provider,
      amountIdr: paymentConfig.priceIdr || adminSettings.pricingIDR || 0,
      merchantName:
        paymentConfig.merchantName ||
        paymentConfig.staticQris.merchantName ||
        'Corra Studio',
      metadata: {
        screen: 'PaymentScreen',
        qrisConfigured: Boolean(
          paymentConfig.staticQris.imageUrl || adminSettings.qrisImageUrl,
        ),
        dokuEnvironment: paymentConfig.doku.environment,
      },
    });

    transactionIdRef.current = transaction.id;

    return () => {
      if (transactionIdRef.current) {
        cancelPaymentTransaction(
          transactionIdRef.current,
          'left_payment_screen_before_confirmation',
        );
      }
    };
  }, [
    adminSettings.pricingIDR,
    adminSettings.qrisImageUrl,
    cancelPaymentTransaction,
    createPaymentTransaction,
    paymentConfig.doku.environment,
    paymentConfig.merchantName,
    paymentConfig.priceIdr,
    paymentConfig.provider,
    paymentConfig.staticQris.imageUrl,
    paymentConfig.staticQris.merchantName,
  ]);

"""

if "left_payment_screen_before_confirmation" not in text:
    marker = "  const handleVoucherSubmit = (event: React.FormEvent) => {"
    if marker not in text:
        raise SystemExit("Could not find handleVoucherSubmit marker.")
    text = text.replace(marker, effect_block + marker)

text = text.replace(
    """      setTimeout(() => {
        onPaymentSuccess(cleanCode);
      }, 900);""",
    """      setTimeout(() => {
        if (transactionIdRef.current) {
          confirmPaymentTransaction(transactionIdRef.current, {
            status: 'voucher_used',
            voucherCode: cleanCode,
            confirmationCode: `VOUCHER_${cleanCode}`,
            metadata: {
              voucherValidatedAt: new Date().toISOString(),
            },
          });
        }

        onPaymentSuccess(cleanCode);
      }, 900);"""
)

text = text.replace(
    """  const handleConfirmPayment = () => {
    playRetroBeep('success');
    setIsProcessingPayment(true);

    setTimeout(() => {
      onPaymentSuccess(getPaymentSuccessCode(currentProvider));
    }, 1000);
  };""",
    """  const handleConfirmPayment = () => {
    playRetroBeep('success');
    setIsProcessingPayment(true);

    const confirmationCode = getPaymentSuccessCode(currentProvider);

    setTimeout(() => {
      if (transactionIdRef.current) {
        confirmPaymentTransaction(transactionIdRef.current, {
          status: 'confirmed',
          confirmationCode,
          metadata: {
            confirmedBy: paymentConfig.requireOperatorConfirmation
              ? 'operator_manual_confirmation'
              : 'customer_self_confirmation',
            confirmedAtProvider: currentProvider,
          },
        });
      }

      onPaymentSuccess(confirmationCode);
    }, 1000);
  };"""
)

path.write_text(text)
print("PATCH file: apps/booth-ui/src/components/PaymentScreen.tsx")
PY

echo ""
echo "Writing PaymentTransactionsPanel..."

write_file "apps/booth-ui/src/components/admin/PaymentTransactionsPanel.tsx" <<'TSX'
import React from 'react';
import {
  usePaymentTransactions,
  type CorraPaymentTransaction,
} from '../../payments';

function formatRupiah(value: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(value || 0);
}

function formatDateTime(value: string | null | undefined): string {
  if (!value) {
    return '-';
  }

  return new Intl.DateTimeFormat('id-ID', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function getStatusClassName(status: CorraPaymentTransaction['status']): string {
  if (status === 'confirmed') {
    return 'bg-emerald-100 text-emerald-700';
  }

  if (status === 'voucher_used') {
    return 'bg-purple-100 text-purple-700';
  }

  if (status === 'pending') {
    return 'bg-amber-100 text-amber-700';
  }

  if (status === 'failed') {
    return 'bg-red-100 text-red-700';
  }

  return 'bg-stone-100 text-stone-600';
}

export default function PaymentTransactionsPanel() {
  const { transactions, currentTransaction, clearPaymentTransactions } =
    usePaymentTransactions();

  const latestTransactions = transactions.slice(0, 10);

  return (
    <div className="rounded-3xl border border-[var(--corra-border)] bg-[var(--corra-surface)] p-6 text-[var(--corra-text)]">
      <div className="mb-5 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h2 className="font-black text-2xl">Payment Transactions</h2>
          <p className="text-sm text-[var(--corra-muted)]">
            Local transaction history for booth payment flow. Supabase sync
            masuk phase berikutnya.
          </p>
        </div>

        <button
          type="button"
          onClick={clearPaymentTransactions}
          className="rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-2 text-xs font-black"
        >
          Clear History
        </button>
      </div>

      {currentTransaction && (
        <div className="mb-5 rounded-2xl border border-[var(--corra-border)] bg-white/80 p-4">
          <p className="text-xs font-black uppercase tracking-wider text-[var(--corra-muted)]">
            Current Transaction
          </p>
          <p className="mt-1 font-mono text-xs">{currentTransaction.id}</p>
          <div className="mt-3 flex flex-wrap gap-2">
            <span
              className={`rounded-full px-3 py-1 text-xs font-black ${getStatusClassName(
                currentTransaction.status,
              )}`}
            >
              {currentTransaction.status}
            </span>
            <span className="rounded-full bg-stone-100 px-3 py-1 text-xs font-black text-stone-600">
              {currentTransaction.provider}
            </span>
            <span className="rounded-full bg-stone-100 px-3 py-1 text-xs font-black text-stone-600">
              {formatRupiah(currentTransaction.amountIdr)}
            </span>
          </div>
        </div>
      )}

      {latestTransactions.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-[var(--corra-border)] bg-white/60 p-6 text-center text-sm font-bold text-[var(--corra-muted)]">
          No payment transactions yet.
        </div>
      ) : (
        <div className="overflow-x-auto rounded-2xl border border-[var(--corra-border)]">
          <table className="min-w-full divide-y divide-[var(--corra-border)] bg-white text-left text-xs">
            <thead className="bg-stone-50 text-[var(--corra-muted)]">
              <tr>
                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Time
                </th>
                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Provider
                </th>
                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Amount
                </th>
                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Status
                </th>
                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Code
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[var(--corra-border)]">
              {latestTransactions.map((transaction) => (
                <tr key={transaction.id}>
                  <td className="px-4 py-3 font-mono">
                    {formatDateTime(transaction.createdAt)}
                  </td>
                  <td className="px-4 py-3 font-bold">
                    {transaction.provider}
                  </td>
                  <td className="px-4 py-3 font-black">
                    {formatRupiah(transaction.amountIdr)}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`rounded-full px-3 py-1 font-black ${getStatusClassName(
                        transaction.status,
                      )}`}
                    >
                      {transaction.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-mono">
                    {transaction.voucherCode ||
                      transaction.confirmationCode ||
                      transaction.cancelReason ||
                      transaction.failureReason ||
                      '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="mt-4 text-xs leading-relaxed text-[var(--corra-muted)]">
        This is local development history only. Production transaction records
        should sync to Supabase sessions/transactions table.
      </p>
    </div>
  );
}
TSX

echo ""
echo "Patching AdminPanel with transaction panel..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

if "PaymentTransactionsPanel" not in text:
    if "PaymentSettingsPanel from './admin/PaymentSettingsPanel';" in text:
        text = text.replace(
            "import PaymentSettingsPanel from './admin/PaymentSettingsPanel';",
            "import PaymentSettingsPanel from './admin/PaymentSettingsPanel';\nimport PaymentTransactionsPanel from './admin/PaymentTransactionsPanel';"
        )
    else:
        lines = text.splitlines()
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
        lines.insert(insert_at, "import PaymentTransactionsPanel from './admin/PaymentTransactionsPanel';")
        text = "\n".join(lines) + "\n"

if "<PaymentTransactionsPanel />" not in text:
    if "<PaymentSettingsPanel />" in text:
        text = text.replace(
            "<PaymentSettingsPanel />",
            "<PaymentSettingsPanel />\n        <div className=\"mt-6\">\n          <PaymentTransactionsPanel />\n        </div>",
            1
        )
    else:
        marker = "      {/* Main double column form container */}"
        if marker not in text:
            raise SystemExit("Could not find insertion point in AdminPanel.tsx")
        text = text.replace(
            marker,
            "      <div className=\"mt-6\">\n        <PaymentTransactionsPanel />\n      </div>\n\n" + marker,
            1
        )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/components/AdminPanel.tsx")
PY

echo ""
echo "Writing docs..."

write_file "docs/phase-8c1-payment-transaction-state.md" <<'MD'
# Phase 8C1 - Payment Transaction State

## Added

- Local transaction state
- PaymentTransactionProvider
- Payment transaction statuses:
  - pending
  - confirmed
  - voucher_used
  - cancelled
  - failed
- PaymentScreen creates a pending transaction when opened
- Confirm payment updates transaction to confirmed
- Valid voucher updates transaction to voucher_used
- Leaving payment screen before confirmation cancels pending transaction
- Admin Panel transaction history

## Next

- Sync transactions to Supabase
- Connect DOKU payment status to transaction status
- Use transaction ID as payment reference/external ID
MD

echo ""
echo "Verifying..."

[ -f "apps/booth-ui/src/payments/PaymentTransactionProvider.tsx" ] || fail "Missing PaymentTransactionProvider."
grep -q "PaymentTransactionProvider" apps/booth-ui/src/main.tsx || fail "main.tsx missing PaymentTransactionProvider."
grep -q "usePaymentTransactions" apps/booth-ui/src/components/PaymentScreen.tsx || fail "PaymentScreen missing transaction hook."
grep -q "left_payment_screen_before_confirmation" apps/booth-ui/src/components/PaymentScreen.tsx || fail "PaymentScreen missing cancel transaction flow."
grep -q "PaymentTransactionsPanel" apps/booth-ui/src/components/AdminPanel.tsx || fail "AdminPanel missing PaymentTransactionsPanel."

echo ""
echo "========================================"
echo " Phase 8C1 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  pnpm --filter @corra/booth-ui dev -- --host 0.0.0.0 --port 5173"
echo "  git add ."
echo "  git commit -m \"feat: add payment transaction state\""
echo "  git push origin main"
echo ""
