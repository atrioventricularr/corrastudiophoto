#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D1C2B2 - DOKU Status Polling"
echo "========================================"

FILE="apps/booth-ui/src/components/PaymentScreen.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: PaymentScreen.tsx not found."
  exit 1
}

[ -f "apps/booth-ui/src/payments/payment-status-api.ts" ] || {
  echo "ERROR: payment-status-api.ts not found. Run 8D1C2B1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/PaymentScreen.tsx")
text = path.read_text()

# 1. Add status helper imports into existing payments import block.
if "getPaymentTransactionStatus" not in text:
    text = text.replace(
        """  createDokuQris,
  isCreateDokuQrisConfigured,""",
        """  createDokuQris,
  getPaymentTransactionStatus,
  isCreateDokuQrisConfigured,
  isPaymentStatusApiConfigured,"""
    )

# 2. Add polling states.
state_marker = """  const [dokuQrisError, setDokuQrisError] = useState('');
  const dokuQrisText = extractDokuQrisText(dokuQrisResult);"""

state_patch = """  const [dokuQrisError, setDokuQrisError] = useState('');
  const [isPollingDokuStatus, setIsPollingDokuStatus] = useState(false);
  const [dokuRemoteStatus, setDokuRemoteStatus] = useState('idle');
  const [dokuStatusMessage, setDokuStatusMessage] = useState('');
  const dokuQrisText = extractDokuQrisText(dokuQrisResult);"""

if state_marker in text and "dokuRemoteStatus" not in text:
    text = text.replace(state_marker, state_patch)

# 3. Reset status before generating new QRIS.
if "setDokuRemoteStatus('generating')" not in text:
    text = text.replace(
        """    setDokuQrisError('');
    setIsGeneratingDokuQris(true);""",
        """    setDokuQrisError('');
    setDokuStatusMessage('');
    setDokuRemoteStatus('generating');
    setIsGeneratingDokuQris(true);"""
    )

# 4. Set generated/error status after createDokuQris.
if "setDokuRemoteStatus('waiting_payment')" not in text:
    text = text.replace(
        """      if (!result.ok) {
        setDokuQrisError(result.error || 'Failed to generate DOKU QRIS.');
      }""",
        """      if (!result.ok) {
        setDokuRemoteStatus('generate_failed');
        setDokuQrisError(result.error || 'Failed to generate DOKU QRIS.');
      } else {
        setDokuRemoteStatus('waiting_payment');
        setDokuStatusMessage('QRIS generated. Waiting for payment confirmation...');
      }"""
    )

# 5. Add polling effect after transaction creation effect.
if "AUTO_POLL_DOKU_PAYMENT_STATUS" not in text:
    marker = "  const handleVoucherSubmit = (event: React.FormEvent) => {"
    effect = """  // AUTO_POLL_DOKU_PAYMENT_STATUS
  useEffect(() => {
    if (currentProvider !== 'DOKU_QRIS') {
      return;
    }

    if (!dokuQrisResult?.ok || !transactionIdRef.current) {
      return;
    }

    if (!isPaymentStatusApiConfigured()) {
      setDokuStatusMessage(
        'Payment status API belum dikonfigurasi di .env.local.',
      );
      return;
    }

    let isCancelled = false;
    let attempt = 0;
    let timer: number | undefined;

    const pollStatus = async () => {
      if (isCancelled || !transactionIdRef.current) {
        return;
      }

      attempt += 1;
      setIsPollingDokuStatus(true);

      const result = await getPaymentTransactionStatus({
        transactionId: transactionIdRef.current,
      });

      if (isCancelled) {
        return;
      }

      const nextStatus = result.status || 'unknown';
      setDokuRemoteStatus(nextStatus);

      if (nextStatus === 'confirmed' || nextStatus === 'voucher_used') {
        setIsPollingDokuStatus(false);
        setDokuStatusMessage('DOKU payment confirmed.');

        confirmPaymentTransaction(transactionIdRef.current, {
          status: 'confirmed',
          confirmationCode:
            String(result.transaction?.confirmation_code || '') ||
            `DOKU_CONFIRMED_${transactionIdRef.current}`,
          metadata: {
            remoteStatus: nextStatus,
            remoteTransaction: result.transaction || null,
          },
        });

        playRetroBeep('success');

        window.setTimeout(() => {
          onPaymentSuccess(`DOKU_CONFIRMED_${transactionIdRef.current}`);
        }, 800);

        return;
      }

      if (nextStatus === 'failed' || nextStatus === 'cancelled') {
        setIsPollingDokuStatus(false);
        setDokuQrisError(
          result.error || `DOKU payment status: ${nextStatus}`,
        );
        return;
      }

      setDokuStatusMessage(
        result.found
          ? `Waiting for DOKU payment confirmation... (${nextStatus})`
          : 'Waiting for DOKU webhook notification...',
      );

      if (attempt < 60) {
        timer = window.setTimeout(pollStatus, 3000);
      } else {
        setIsPollingDokuStatus(false);
        setDokuStatusMessage(
          'Payment status polling stopped. You can confirm manually or regenerate QRIS.',
        );
      }
    };

    pollStatus();

    return () => {
      isCancelled = true;

      if (timer) {
        window.clearTimeout(timer);
      }
    };
  }, [
    confirmPaymentTransaction,
    currentProvider,
    dokuQrisResult?.ok,
    onPaymentSuccess,
  ]);

"""
    if marker not in text:
        raise SystemExit("Could not find handleVoucherSubmit marker.")
    text = text.replace(marker, effect + marker)

# 6. Add status UI after QRIS generated block start.
old_ui = """                    <p className="mt-1 font-mono">
                      Ref: {dokuQrisResult.request?.partnerReferenceNo ||
                        dokuQrisResult.transactionId}
                    </p>"""

new_ui = """                    <p className="mt-1 font-mono">
                      Ref: {dokuQrisResult.request?.partnerReferenceNo ||
                        dokuQrisResult.transactionId}
                    </p>

                    <div className="mt-3 rounded-xl bg-white p-3">
                      <p className="text-[10px] font-black uppercase tracking-wider">
                        Remote Status
                      </p>
                      <p className="mt-1 font-mono text-xs">
                        {isPollingDokuStatus ? 'Polling · ' : ''}
                        {dokuRemoteStatus}
                      </p>
                      {dokuStatusMessage && (
                        <p className="mt-1 text-[10px] font-bold">
                          {dokuStatusMessage}
                        </p>
                      )}
                    </div>"""

if old_ui in text and "Remote Status" not in text:
    text = text.replace(old_ui, new_ui)

# 7. Update confirm button text for DOKU.
if "Waiting DOKU Payment..." not in text:
    text = text.replace(
        """{isProcessingPayment ? dict.processingBtn : dict.confirmBtn}""",
        """{isProcessingPayment
                ? dict.processingBtn
                : currentProvider === 'DOKU_QRIS' && isPollingDokuStatus
                  ? 'Waiting DOKU Payment...'
                  : dict.confirmBtn}"""
    )

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "AUTO_POLL_DOKU_PAYMENT_STATUS" "$FILE" || {
  echo "ERROR: polling effect missing."
  exit 1
}

grep -q "getPaymentTransactionStatus" "$FILE" || {
  echo "ERROR: status helper missing."
  exit 1
}

grep -q "Remote Status" "$FILE" || {
  echo "ERROR: remote status UI missing."
  exit 1
}

echo ""
echo "Phase 8D1C2B2 completed."
