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


function getSyncClassName(
  status: CorraPaymentTransaction['syncStatus'],
): string {
  if (status === 'synced') {
    return 'bg-emerald-100 text-emerald-700';
  }

  if (status === 'syncing') {
    return 'bg-blue-100 text-blue-700';
  }

  if (status === 'failed') {
    return 'bg-red-100 text-red-700';
  }

  if (status === 'skipped') {
    return 'bg-amber-100 text-amber-700';
  }

  return 'bg-stone-100 text-stone-600';
}

export default function PaymentTransactionsPanel() {
  const {
    transactions,
    currentTransaction,
    clearPaymentTransactions,
    syncPendingTransactions,
  } = usePaymentTransactions();

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

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={syncPendingTransactions}
            className="rounded-2xl bg-[var(--corra-primary)] px-4 py-2 text-xs font-black text-white"
          >
            Sync Pending
          </button>

          <button
            type="button"
            onClick={clearPaymentTransactions}
            className="rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-2 text-xs font-black"
          >
            Clear History
          </button>
        </div>
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
            <span
              className={`rounded-full px-3 py-1 text-xs font-black ${getSyncClassName(
                currentTransaction.syncStatus || 'idle',
              )}`}
            >
              Sync: {currentTransaction.syncStatus || 'idle'}
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
                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Sync
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
                  <td className="px-4 py-3">
                    <span
                      className={`rounded-full px-3 py-1 font-black ${getSyncClassName(
                        transaction.syncStatus || 'idle',
                      )}`}
                    >
                      {transaction.syncStatus || 'idle'}
                    </span>

                    {transaction.syncError && (
                      <p className="mt-1 max-w-xs truncate text-[10px] font-bold text-red-600">
                        {transaction.syncError}
                      </p>
                    )}

                    {transaction.syncedAt && (
                      <p className="mt-1 text-[10px] font-mono text-[var(--corra-muted)]">
                        {formatDateTime(transaction.syncedAt)}
                      </p>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="mt-4 text-xs leading-relaxed text-[var(--corra-muted)]">
        Transactions sync to Supabase booth_payment_transactions after payment
        confirmation/cancellation. Failed sync can be retried manually.
      </p>
    </div>
  );
}
