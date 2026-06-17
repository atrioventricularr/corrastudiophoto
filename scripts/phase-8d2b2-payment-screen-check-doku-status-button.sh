#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D2B2 - PaymentScreen Check DOKU Status Button"
echo "========================================"

FILE="apps/booth-ui/src/components/PaymentScreen.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: PaymentScreen.tsx not found."
  exit 1
}

[ -f "apps/booth-ui/src/payments/doku-status-api.ts" ] || {
  echo "ERROR: doku-status-api.ts not found. Run 8D2B1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/PaymentScreen.tsx")
text = path.read_text()

# 1. Add DOKU status helper imports.
if "checkDokuQrisStatus" not in text:
    text = text.replace(
        """  createDokuQris,
  getPaymentTransactionStatus,""",
        """  checkDokuQrisStatus,
  createDokuQris,
  getPaymentTransactionStatus,"""
    )

if "isCheckDokuQrisStatusConfigured" not in text:
    text = text.replace(
        """  isCreateDokuQrisConfigured,
  isPaymentStatusApiConfigured,""",
        """  isCheckDokuQrisStatusConfigured,
  isCreateDokuQrisConfigured,
  isPaymentStatusApiConfigured,"""
    )

# 2. Add checking state.
state_marker = """  const [isPollingDokuStatus, setIsPollingDokuStatus] = useState(false);
  const [dokuRemoteStatus, setDokuRemoteStatus] = useState('idle');"""

state_patch = """  const [isPollingDokuStatus, setIsPollingDokuStatus] = useState(false);
  const [isCheckingDokuStatus, setIsCheckingDokuStatus] = useState(false);
  const [dokuRemoteStatus, setDokuRemoteStatus] = useState('idle');"""

if state_marker in text and "isCheckingDokuStatus" not in text:
    text = text.replace(state_marker, state_patch)

# 3. Add manual check handler before handleConfirmPayment.
if "handleCheckDokuStatus" not in text:
    marker = "  const handleConfirmPayment = () => {"
    handler = """  const handleCheckDokuStatus = async () => {
    if (!transactionIdRef.current) {
      setDokuQrisError('Transaction ID belum tersedia.');
      return;
    }

    if (!isCheckDokuQrisStatusConfigured()) {
      setDokuQrisError(
        'DOKU check status API belum dikonfigurasi di .env.local.',
      );
      return;
    }

    setDokuQrisError('');
    setDokuStatusMessage('Checking DOKU payment status...');
    setIsCheckingDokuStatus(true);

    try {
      const result = await checkDokuQrisStatus({
        transactionId: transactionIdRef.current,
        environment: paymentConfig.doku.environment,
      });

      const nextStatus = result.status || 'unknown';
      setDokuRemoteStatus(nextStatus);

      if (nextStatus === 'confirmed' || nextStatus === 'voucher_used') {
        setDokuStatusMessage('DOKU payment confirmed from status inquiry.');

        confirmPaymentTransaction(transactionIdRef.current, {
          status: 'confirmed',
          confirmationCode:
            String(result.transactionRecord?.confirmation_code || '') ||
            `DOKU_STATUS_CONFIRMED_${transactionIdRef.current}`,
          metadata: {
            statusInquiry: true,
            remoteStatus: nextStatus,
            dokuStatusResponse: result.doku || null,
            transactionRecord: result.transactionRecord || null,
          },
        });

        playRetroBeep('success');

        window.setTimeout(() => {
          onPaymentSuccess(`DOKU_STATUS_CONFIRMED_${transactionIdRef.current}`);
        }, 800);

        return;
      }

      if (nextStatus === 'failed' || nextStatus === 'cancelled') {
        setDokuQrisError(
          result.error || `DOKU payment status inquiry: ${nextStatus}`,
        );
        return;
      }

      setDokuStatusMessage(
        result.error
          ? `DOKU status: ${nextStatus}. ${result.error}`
          : `DOKU status: ${nextStatus}. Payment not confirmed yet.`,
      );
    } finally {
      setIsCheckingDokuStatus(false);
    }
  };

"""
    if marker not in text:
        raise SystemExit("Could not find handleConfirmPayment marker.")
    text = text.replace(marker, handler + marker)

# 4. Add button after Generate DOKU QRIS button.
button_marker = """                {!paymentConfig.doku.merchantId && (
                  <p className="mt-3 text-xs font-bold text-red-700">
                    DOKU Merchant ID belum diisi di Admin Payment Settings.
                  </p>
                )}"""

button_patch = """                <button
                  type="button"
                  onClick={handleCheckDokuStatus}
                  disabled={
                    isCheckingDokuStatus ||
                    !dokuQrisResult?.ok ||
                    !isCheckDokuQrisStatusConfigured()
                  }
                  className="mt-3 w-full rounded-2xl border border-blue-200 bg-white px-5 py-3 text-xs font-black text-blue-800 disabled:opacity-50"
                >
                  {isCheckingDokuStatus
                    ? 'Checking DOKU Status...'
                    : 'Check DOKU Status'}
                </button>

                {!paymentConfig.doku.merchantId && (
                  <p className="mt-3 text-xs font-bold text-red-700">
                    DOKU Merchant ID belum diisi di Admin Payment Settings.
                  </p>
                )}"""

if button_marker in text and "Check DOKU Status" not in text:
    text = text.replace(button_marker, button_patch)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "handleCheckDokuStatus" "$FILE" || {
  echo "ERROR: handleCheckDokuStatus missing."
  exit 1
}

grep -q "Check DOKU Status" "$FILE" || {
  echo "ERROR: Check DOKU Status button missing."
  exit 1
}

grep -q "checkDokuQrisStatus" "$FILE" || {
  echo "ERROR: checkDokuQrisStatus missing."
  exit 1
}

echo ""
echo "Phase 8D2B2 completed."
