#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D1C3 - Record DOKU Pending Transaction"
echo "========================================"

FILE="supabase/functions/create-doku-qris/index.ts"

[ -f "$FILE" ] || {
  echo "ERROR: create-doku-qris function not found. Run 8D1A first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("supabase/functions/create-doku-qris/index.ts")
text = path.read_text()

if "createClient" not in text:
    text = "import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';\n\n" + text

old = """    const dokuBody = await dokuResponse.json().catch(() => null);

    return jsonResponse(
      {
        ok: dokuResponse.ok,
        transactionId,
        environment,
        request: {
          partnerReferenceNo: transactionId,
          amountIdr,
          merchantId,
          terminalId,
          validityPeriod,
        },
        doku: dokuBody,
        error: dokuResponse.ok
          ? null
          : dokuBody?.responseMessage || `DOKU error ${dokuResponse.status}`,
      },
      dokuResponse.ok ? 200 : 502,
    );"""

new = """    const dokuBody = await dokuResponse.json().catch(() => null);

    let transactionRecord: unknown = null;
    let transactionRecordError: string | null = null;

    if (dokuResponse.ok) {
      const supabaseUrl = Deno.env.get('SUPABASE_URL');
      const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

      if (supabaseUrl && serviceRoleKey) {
        const supabase = createClient(supabaseUrl, serviceRoleKey, {
          auth: {
            persistSession: false,
          },
        });

        const { data: existingTransaction } = await supabase
          .from('booth_payment_transactions')
          .select('transaction_id,status,metadata')
          .eq('transaction_id', transactionId)
          .maybeSingle();

        const pendingRow = {
          transaction_id: transactionId,
          provider: 'DOKU_QRIS',
          status: 'pending',
          amount_idr: amountIdr,
          currency: 'IDR',
          merchant_name: merchantId,
          source: 'create-doku-qris',
          metadata: {
            ...(existingTransaction?.metadata || {}),
            dokuEnvironment: environment,
            dokuExternalId: externalId,
            dokuQrisGeneratedAt: new Date().toISOString(),
            dokuRequest: {
              partnerReferenceNo: transactionId,
              amountIdr,
              merchantId,
              terminalId,
              validityPeriod,
            },
            dokuResponse: dokuBody,
          },
          client_created_at: new Date().toISOString(),
          client_updated_at: new Date().toISOString(),
          synced_at: new Date().toISOString(),
        };

        if (!existingTransaction) {
          const { data, error } = await supabase
            .from('booth_payment_transactions')
            .insert(pendingRow)
            .select('*')
            .single();

          transactionRecord = data;
          transactionRecordError = error?.message || null;
        } else if (existingTransaction.status === 'pending') {
          const { data, error } = await supabase
            .from('booth_payment_transactions')
            .update({
              amount_idr: pendingRow.amount_idr,
              merchant_name: pendingRow.merchant_name,
              metadata: pendingRow.metadata,
              client_updated_at: pendingRow.client_updated_at,
              synced_at: pendingRow.synced_at,
            })
            .eq('transaction_id', transactionId)
            .select('*')
            .single();

          transactionRecord = data;
          transactionRecordError = error?.message || null;
        } else {
          transactionRecord = existingTransaction;
        }
      } else {
        transactionRecordError =
          'SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY unavailable; skipped pending transaction record.';
      }
    }

    return jsonResponse(
      {
        ok: dokuResponse.ok,
        transactionId,
        environment,
        request: {
          partnerReferenceNo: transactionId,
          amountIdr,
          merchantId,
          terminalId,
          validityPeriod,
        },
        transactionRecord,
        transactionRecordError,
        doku: dokuBody,
        error: dokuResponse.ok
          ? null
          : dokuBody?.responseMessage || `DOKU error ${dokuResponse.status}`,
      },
      dokuResponse.ok ? 200 : 502,
    );"""

if old not in text:
    raise SystemExit("Could not find DOKU response return block. Function may have changed.")

text = text.replace(old, new)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "transactionRecord" "$FILE" || {
  echo "ERROR: transactionRecord patch missing."
  exit 1
}

grep -q "booth_payment_transactions" "$FILE" || {
  echo "ERROR: Supabase transaction table usage missing."
  exit 1
}

echo ""
echo "Phase 8D1C3 completed."
