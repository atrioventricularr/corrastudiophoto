#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8C2C2 - Provider Auto Sync"
echo "========================================"

FILE="apps/booth-ui/src/payments/PaymentTransactionProvider.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: PaymentTransactionProvider.tsx not found. Run 8C1 first."
  exit 1
}

[ -f "apps/booth-ui/src/payments/supabase-payment-sync.ts" ] || {
  echo "ERROR: supabase-payment-sync.ts not found. Run 8C2C1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/payments/PaymentTransactionProvider.tsx")
text = path.read_text()

# Add sync helper import
if "syncPaymentTransactionToSupabase" not in text:
    text = text.replace(
        "} from './transaction-types';",
        "} from './transaction-types';\nimport { syncPaymentTransactionToSupabase } from './supabase-payment-sync';"
    )

# Add sync fields to newly created transactions
if "syncStatus: 'idle'" not in text:
    text = text.replace(
        "        metadata: input.metadata || {},",
        """        metadata: input.metadata || {},
        syncStatus: 'idle',
        syncedAt: null,
        syncError: null,"""
    )

# Replace no-op syncPendingTransactions with real sync
pattern = r"""  const syncPendingTransactions = useCallback\(async \(\) => \{
    // Phase 8C2C2 will replace this with real Supabase sync.
  \}, \[\]\);

"""

real_sync = """  const syncPendingTransactions = useCallback(async () => {
    const toSync = transactions.filter((transaction) => {
      return (
        transaction.status !== 'pending' &&
        transaction.syncStatus !== 'synced' &&
        transaction.syncStatus !== 'syncing'
      );
    });

    for (const transaction of toSync) {
      const syncingAt = new Date().toISOString();

      setTransactions((current) =>
        sortTransactions(
          current.map((item) =>
            item.id === transaction.id
              ? {
                  ...item,
                  syncStatus: 'syncing',
                  syncError: null,
                  updatedAt: syncingAt,
                }
              : item,
          ),
        ),
      );

      const result = await syncPaymentTransactionToSupabase(transaction);
      const finishedAt = new Date().toISOString();

      setTransactions((current) =>
        sortTransactions(
          current.map((item) => {
            if (item.id !== transaction.id) {
              return item;
            }

            if (result.ok) {
              return {
                ...item,
                syncStatus: 'synced',
                syncedAt: result.syncedAt || finishedAt,
                syncError: null,
                updatedAt: finishedAt,
              };
            }

            return {
              ...item,
              syncStatus: result.skipped ? 'skipped' : 'failed',
              syncError: result.error || 'Unknown sync error.',
              updatedAt: finishedAt,
            };
          }),
        ),
      );
    }
  }, [transactions]);

"""

if re.search(pattern, text):
    text = re.sub(pattern, real_sync, text)
elif "const syncPendingTransactions = useCallback" not in text:
    marker = "  const clearPaymentTransactions = useCallback(() => {"
    if marker not in text:
        raise SystemExit("Could not find clearPaymentTransactions marker.")
    text = text.replace(marker, real_sync + marker, 1)

# Add auto-sync effect once
if "AUTO_SYNC_PAYMENT_TRANSACTIONS" not in text:
    marker = "  const clearPaymentTransactions = useCallback(() => {"
    auto_effect = """  // AUTO_SYNC_PAYMENT_TRANSACTIONS
  useEffect(() => {
    const hasAutoSyncableTransaction = transactions.some((transaction) => {
      return (
        transaction.status !== 'pending' &&
        (!transaction.syncStatus || transaction.syncStatus === 'idle')
      );
    });

    if (!hasAutoSyncableTransaction) {
      return;
    }

    const timer = window.setTimeout(() => {
      syncPendingTransactions();
    }, 700);

    return () => window.clearTimeout(timer);
  }, [syncPendingTransactions, transactions]);

"""
    if marker not in text:
        raise SystemExit("Could not find clearPaymentTransactions marker for auto effect.")
    text = text.replace(marker, auto_effect + marker, 1)

# Ensure value includes syncPendingTransactions
if "      syncPendingTransactions," not in text:
    text = text.replace(
        "      clearPaymentTransactions,",
        "      clearPaymentTransactions,\n      syncPendingTransactions,",
        1
    )

# Ensure useMemo dependency includes syncPendingTransactions
dependency_block_pattern = r"""  \}, \[
([\s\S]*?)
  \]\);"""
matches = list(re.finditer(dependency_block_pattern, text))
if matches:
    # last useMemo dependency block in this provider is usually the value deps
    last = matches[-1]
    block = last.group(0)
    if "syncPendingTransactions" not in block:
        new_block = block.replace(
            "    clearPaymentTransactions,",
            "    clearPaymentTransactions,\n    syncPendingTransactions,"
        )
        text = text[:last.start()] + new_block + text[last.end():]

path.write_text(text)
print("PATCH file: apps/booth-ui/src/payments/PaymentTransactionProvider.tsx")
PY

echo ""
echo "Verifying..."

grep -q "syncPaymentTransactionToSupabase" "$FILE" || {
  echo "ERROR: sync helper import missing."
  exit 1
}

grep -q "AUTO_SYNC_PAYMENT_TRANSACTIONS" "$FILE" || {
  echo "ERROR: auto sync effect missing."
  exit 1
}

grep -q "syncStatus: 'syncing'" "$FILE" || {
  echo "ERROR: syncing status patch missing."
  exit 1
}

echo ""
echo "Phase 8C2C2 completed."
