#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8C2D - Admin Sync Status"
echo "========================================"

FILE="apps/booth-ui/src/components/admin/PaymentTransactionsPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: PaymentTransactionsPanel.tsx not found. Run 8C1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/PaymentTransactionsPanel.tsx")
text = path.read_text()

# 1. Destructure syncPendingTransactions
old = """  const { transactions, currentTransaction, clearPaymentTransactions } =
    usePaymentTransactions();"""
new = """  const {
    transactions,
    currentTransaction,
    clearPaymentTransactions,
    syncPendingTransactions,
  } = usePaymentTransactions();"""

if old in text:
    text = text.replace(old, new)

# 2. Add sync status style helper
if "function getSyncClassName" not in text:
    marker = "export default function PaymentTransactionsPanel() {"
    helper = """
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

"""
    text = text.replace(marker, helper + marker)

# 3. Replace Clear History single button with Sync Pending + Clear History
old_button = """        <button
          type="button"
          onClick={clearPaymentTransactions}
          className="rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-2 text-xs font-black"
        >
          Clear History
        </button>"""

new_button = """        <div className="flex flex-wrap gap-2">
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
        </div>"""

if old_button in text and "Sync Pending" not in text:
    text = text.replace(old_button, new_button)

# 4. Add sync badge to Current Transaction box
old_current_badges = """            <span className="rounded-full bg-stone-100 px-3 py-1 text-xs font-black text-stone-600">
              {formatRupiah(currentTransaction.amountIdr)}
            </span>"""

new_current_badges = """            <span className="rounded-full bg-stone-100 px-3 py-1 text-xs font-black text-stone-600">
              {formatRupiah(currentTransaction.amountIdr)}
            </span>
            <span
              className={`rounded-full px-3 py-1 text-xs font-black ${getSyncClassName(
                currentTransaction.syncStatus || 'idle',
              )}`}
            >
              Sync: {currentTransaction.syncStatus || 'idle'}
            </span>"""

if old_current_badges in text and "Sync: {currentTransaction.syncStatus" not in text:
    text = text.replace(old_current_badges, new_current_badges)

# 5. Add Sync table header
old_header = """                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Code
                </th>"""

new_header = """                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Code
                </th>
                <th className="px-4 py-3 font-black uppercase tracking-wider">
                  Sync
                </th>"""

if old_header in text and "                  Sync\n                </th>" not in text:
    text = text.replace(old_header, new_header)

# 6. Add Sync table cell
old_cell = """                  <td className="px-4 py-3 font-mono">
                    {transaction.voucherCode ||
                      transaction.confirmationCode ||
                      transaction.cancelReason ||
                      transaction.failureReason ||
                      '-'}
                  </td>"""

new_cell = """                  <td className="px-4 py-3 font-mono">
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
                  </td>"""

if old_cell in text and "transaction.syncError" not in text:
    text = text.replace(old_cell, new_cell)

# 7. Update note copy
text = text.replace(
    """This is local development history only. Production transaction records
        should sync to Supabase sessions/transactions table.""",
    """Transactions sync to Supabase booth_payment_transactions after payment
        confirmation/cancellation. Failed sync can be retried manually."""
)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "Sync Pending" "$FILE" || {
  echo "ERROR: Sync Pending button missing."
  exit 1
}

grep -q "getSyncClassName" "$FILE" || {
  echo "ERROR: getSyncClassName helper missing."
  exit 1
}

grep -q "transaction.syncError" "$FILE" || {
  echo "ERROR: sync error UI missing."
  exit 1
}

echo ""
echo "Phase 8C2D completed."
