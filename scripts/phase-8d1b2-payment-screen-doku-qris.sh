#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D1B2 - PaymentScreen DOKU QRIS"
echo "========================================"

FILE="apps/booth-ui/src/components/PaymentScreen.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: PaymentScreen.tsx not found."
  exit 1
}

[ -f "apps/booth-ui/src/payments/doku-qris-api.ts" ] || {
  echo "ERROR: doku-qris-api.ts not found. Run 8D1B1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/PaymentScreen.tsx")
text = path.read_text()

# 1. Import DOKU helper
if "createDokuQris" not in text:
    text = text.replace(
        "import { usePaymentSettings, usePaymentTransactions } from '../payments';",
        """import {
  createDokuQris,
  isCreateDokuQrisConfigured,
  usePaymentSettings,
  usePaymentTransactions,
  type CreateDokuQrisResult,
} from '../payments';"""
    )

# 2. Add QR extractor helper
if "function extractDokuQrisText" not in text:
    marker = "function getPaymentSuccessCode(provider: string): string {"
    helper = """
function findFirstQrisLikeString(value: unknown): string {
  if (!value) {
    return '';
  }

  if (typeof value === 'string') {
    const normalized = value.toLowerCase();

    if (
      normalized.includes('000201') ||
      normalized.includes('qris') ||
      normalized.includes('qr')
    ) {
      return value;
    }

    return '';
  }

  if (Array.isArray(value)) {
    for (const item of value) {
      const found = findFirstQrisLikeString(item);

      if (found) {
        return found;
      }
    }

    return '';
  }

  if (typeof value === 'object') {
    for (const item of Object.values(value as Record<string, unknown>)) {
      const found = findFirstQrisLikeString(item);

      if (found) {
        return found;
      }
    }
  }

  return '';
}

function extractDokuQrisText(result: CreateDokuQrisResult | null): string {
  if (!result?.doku) {
    return '';
  }

  return findFirstQrisLikeString(result.doku);
}

"""
    text = text.replace(marker, helper + marker)

# 3. Add state
state_marker = "  const [isProcessingPayment, setIsProcessingPayment] = useState(false);"
state_insert = """  const [isProcessingPayment, setIsProcessingPayment] = useState(false);
  const [isGeneratingDokuQris, setIsGeneratingDokuQris] = useState(false);
  const [dokuQrisResult, setDokuQrisResult] =
    useState<CreateDokuQrisResult | null>(null);
  const [dokuQrisError, setDokuQrisError] = useState('');
  const dokuQrisText = extractDokuQrisText(dokuQrisResult);"""

if state_marker in text and "dokuQrisResult" not in text:
    text = text.replace(state_marker, state_insert)

# 4. Add generate handler
if "handleGenerateDokuQris" not in text:
    marker = "  const handleConfirmPayment = () => {"
    handler = """  const handleGenerateDokuQris = async () => {
    setDokuQrisError('');
    setIsGeneratingDokuQris(true);

    try {
      const transactionId =
        transactionIdRef.current || `CORRA-${Date.now()}`;

      const result = await createDokuQris({
        transactionId,
        amountIdr: effectivePrice,
        merchantId: paymentConfig.doku.merchantId || undefined,
        environment: paymentConfig.doku.environment,
        validityMinutes: 15,
      });

      setDokuQrisResult(result);

      if (!result.ok) {
        setDokuQrisError(result.error || 'Failed to generate DOKU QRIS.');
      }
    } finally {
      setIsGeneratingDokuQris(false);
    }
  };

"""
    text = text.replace(marker, handler + marker)

# 5. Guard confirm payment for DOKU
old_confirm = """  const handleConfirmPayment = () => {
    playRetroBeep('success');
    setIsProcessingPayment(true);"""

new_confirm = """  const handleConfirmPayment = () => {
    if (currentProvider === 'DOKU_QRIS' && !dokuQrisResult?.ok) {
      setDokuQrisError('Generate DOKU QRIS first before confirming payment.');
      return;
    }

    playRetroBeep('success');
    setIsProcessingPayment(true);"""

if old_confirm in text and "Generate DOKU QRIS first before confirming payment" not in text:
    text = text.replace(old_confirm, new_confirm)

# 6. Replace DOKU placeholder block with interactive block
start_token = "{currentProvider === 'DOKU_QRIS' && ("
start = text.find(start_token)
if start == -1:
    raise SystemExit("Could not find DOKU_QRIS render block.")

end_token = "{currentProvider === 'MANUAL_CASH' && ("
end = text.find(end_token, start)
if end == -1:
    raise SystemExit("Could not find MANUAL_CASH block after DOKU block.")

new_block = """{currentProvider === 'DOKU_QRIS' && (
              <div className="w-full max-w-md rounded-3xl border border-blue-100 bg-blue-50 p-6 text-center text-blue-900">
                <QrCode className="mx-auto mb-4 w-20 h-20" />
                <p className="text-sm font-black">DOKU Dynamic QRIS</p>
                <p className="mt-2 text-xs leading-relaxed">
                  Generate QRIS dinamis untuk transaksi ini. Setelah QRIS dibuat,
                  customer scan menggunakan aplikasi bank/e-wallet.
                </p>

                <div className="mt-4 rounded-2xl bg-white p-4 text-left text-xs">
                  <p className="font-black">Status</p>
                  <p className="mt-1 font-mono">
                    Env: {paymentConfig.doku.environment} · Client ID{' '}
                    {paymentConfig.doku.clientId ? 'set' : 'not set'} · Secret{' '}
                    {paymentConfig.doku.isCredentialConfigured ? 'set' : 'not set'}
                  </p>
                </div>

                <button
                  type="button"
                  onClick={handleGenerateDokuQris}
                  disabled={
                    isGeneratingDokuQris ||
                    !isCreateDokuQrisConfigured() ||
                    !paymentConfig.doku.merchantId
                  }
                  className="mt-4 w-full rounded-2xl bg-blue-700 px-5 py-3 text-xs font-black text-white disabled:opacity-50"
                >
                  {isGeneratingDokuQris
                    ? 'Generating QRIS...'
                    : dokuQrisResult?.ok
                      ? 'Regenerate DOKU QRIS'
                      : 'Generate DOKU QRIS'}
                </button>

                {!paymentConfig.doku.merchantId && (
                  <p className="mt-3 text-xs font-bold text-red-700">
                    DOKU Merchant ID belum diisi di Admin Payment Settings.
                  </p>
                )}

                {!isCreateDokuQrisConfigured() && (
                  <p className="mt-3 text-xs font-bold text-red-700">
                    VITE_CREATE_DOKU_QRIS_URL atau VITE_SUPABASE_ANON_KEY belum
                    diatur di .env.local.
                  </p>
                )}

                {dokuQrisError && (
                  <div className="mt-4 rounded-2xl border border-red-200 bg-red-50 p-3 text-xs font-bold text-red-700">
                    {dokuQrisError}
                  </div>
                )}

                {dokuQrisResult?.ok && (
                  <div className="mt-4 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-left text-xs text-emerald-900">
                    <p className="font-black">DOKU QRIS Generated</p>
                    <p className="mt-1 font-mono">
                      Ref: {dokuQrisResult.request?.partnerReferenceNo ||
                        dokuQrisResult.transactionId}
                    </p>

                    {dokuQrisText ? (
                      <div className="mt-3 rounded-xl bg-white p-3">
                        <p className="mb-1 font-black">QR Content</p>
                        <p className="break-all font-mono text-[10px]">
                          {dokuQrisText}
                        </p>
                      </div>
                    ) : (
                      <div className="mt-3 rounded-xl bg-white p-3">
                        <p className="font-black">Raw DOKU Response</p>
                        <pre className="mt-2 max-h-36 overflow-auto whitespace-pre-wrap text-[10px]">
                          {JSON.stringify(dokuQrisResult.doku, null, 2)}
                        </pre>
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}

            """

text = text[:start] + new_block + text[end:]

# 7. Disable confirm button for DOKU until generated
old_button_disabled = "disabled={isProcessingPayment}"
new_button_disabled = "disabled={isProcessingPayment || (currentProvider === 'DOKU_QRIS' && !dokuQrisResult?.ok)}"

if old_button_disabled in text and new_button_disabled not in text:
    text = text.replace(old_button_disabled, new_button_disabled, 1)

path.write_text(text)
print("PATCH file: apps/booth-ui/src/components/PaymentScreen.tsx")
PY

echo ""
echo "Verifying..."

grep -q "handleGenerateDokuQris" "$FILE" || {
  echo "ERROR: DOKU generate handler missing."
  exit 1
}

grep -q "Generate DOKU QRIS" "$FILE" || {
  echo "ERROR: Generate DOKU QRIS button missing."
  exit 1
}

grep -q "createDokuQris" "$FILE" || {
  echo "ERROR: createDokuQris import/usage missing."
  exit 1
}

echo ""
echo "Phase 8D1B2 completed."
