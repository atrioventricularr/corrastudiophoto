import React, { useEffect, useState } from 'react';
import {
  usePaymentSettings,
  type CorraPaymentEnvironment,
  type CorraPaymentProviderId,
} from '../../payments';
import {
  deleteDesktopSecret,
  getDesktopSecretStatus,
  isDesktopSecureVaultAvailable,
  setDesktopSecret,
  type CorraSecretStatus,
} from '../../lib/desktop-secure-vault';

const PAYMENT_PROVIDER_LABELS: Record<CorraPaymentProviderId, string> = {
  STATIC_QRIS: 'Static QRIS PNG',
  DOKU_QRIS: 'DOKU Dynamic QRIS',
  MANUAL_CASH: 'Manual Cash / Operator',
  MAYAR_CHECKOUT: 'Mayar Checkout',
};

function formatRupiah(value: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(value || 0);
}

function SecretStatusBadge({
  status,
}: {
  status: CorraSecretStatus | null;
}) {
  if (!status?.configured) {
    return (
      <span className="rounded-full bg-stone-100 px-3 py-1 text-xs font-black text-stone-500">
        Not configured
      </span>
    );
  }

  return (
    <span className="rounded-full bg-emerald-100 px-3 py-1 text-xs font-black text-emerald-700">
      Configured: {status.maskedValue}
    </span>
  );
}

export default function PaymentSettingsPanel() {
  const { paymentConfig, updatePaymentConfig, resetPaymentConfig } =
    usePaymentSettings();

  const [message, setMessage] = useState('');
  const [dokuSecretInput, setDokuSecretInput] = useState('');
  const [mayarApiKeyInput, setMayarApiKeyInput] = useState('');
  const [dokuSecretStatus, setDokuSecretStatus] =
    useState<CorraSecretStatus | null>(null);
  const [mayarApiKeyStatus, setMayarApiKeyStatus] =
    useState<CorraSecretStatus | null>(null);

  const vaultAvailable = isDesktopSecureVaultAvailable();

  useEffect(() => {
    let cancelled = false;

    async function loadSecretStatuses() {
      const [dokuStatus, mayarStatus] = await Promise.all([
        getDesktopSecretStatus('DOKU_SECRET_KEY'),
        getDesktopSecretStatus('MAYAR_CHECKOUT_API_KEY'),
      ]);

      if (cancelled) {
        return;
      }

      setDokuSecretStatus(dokuStatus);
      setMayarApiKeyStatus(mayarStatus);
    }

    loadSecretStatuses();

    return () => {
      cancelled = true;
    };
  }, []);

  const updateStaticQris = (
    patch: Partial<typeof paymentConfig.staticQris>,
  ) => {
    updatePaymentConfig({
      staticQris: {
        ...paymentConfig.staticQris,
        ...patch,
      },
    });
  };

  const updateDoku = (patch: Partial<typeof paymentConfig.doku>) => {
    updatePaymentConfig({
      doku: {
        ...paymentConfig.doku,
        ...patch,
      },
    });
  };

  const updateManualCash = (
    patch: Partial<typeof paymentConfig.manualCash>,
  ) => {
    updatePaymentConfig({
      manualCash: {
        ...paymentConfig.manualCash,
        ...patch,
      },
    });
  };

  const updateMayarCheckout = (
    patch: Partial<typeof paymentConfig.mayarCheckout>,
  ) => {
    updatePaymentConfig({
      mayarCheckout: {
        ...paymentConfig.mayarCheckout,
        ...patch,
      },
    });
  };

  const handleSaveDokuSecret = async () => {
    setMessage('');

    const status = await setDesktopSecret({
      key: 'DOKU_SECRET_KEY',
      value: dokuSecretInput,
      label: 'DOKU Secret Key',
    });

    setDokuSecretStatus(status);
    setDokuSecretInput('');

    if (status.configured) {
      updateDoku({
        isCredentialConfigured: true,
      });
      setMessage('DOKU Secret Key saved to desktop secure vault.');
    } else {
      setMessage(status.error || 'Failed to save DOKU Secret Key.');
    }
  };

  const handleDeleteDokuSecret = async () => {
    const status = await deleteDesktopSecret('DOKU_SECRET_KEY');

    setDokuSecretStatus(status);
    updateDoku({
      isCredentialConfigured: false,
    });
    setMessage('DOKU Secret Key deleted from secure vault.');
  };

  const handleSaveMayarApiKey = async () => {
    setMessage('');

    const status = await setDesktopSecret({
      key: 'MAYAR_CHECKOUT_API_KEY',
      value: mayarApiKeyInput,
      label: 'Mayar Checkout API Key',
    });

    setMayarApiKeyStatus(status);
    setMayarApiKeyInput('');

    if (status.configured) {
      updateMayarCheckout({
        isConfigured: true,
      });
      setMessage('Mayar Checkout API Key saved to desktop secure vault.');
    } else {
      setMessage(status.error || 'Failed to save Mayar Checkout API Key.');
    }
  };

  const handleDeleteMayarApiKey = async () => {
    const status = await deleteDesktopSecret('MAYAR_CHECKOUT_API_KEY');

    setMayarApiKeyStatus(status);
    updateMayarCheckout({
      isConfigured: false,
    });
    setMessage('Mayar Checkout API Key deleted from secure vault.');
  };

  const handleReset = () => {
    resetPaymentConfig();
    setMessage('Payment settings reset to default.');
  };

  return (
    <div className="rounded-3xl border border-[var(--corra-border)] bg-[var(--corra-surface)] p-6 text-[var(--corra-text)]">
      <div className="mb-5">
        <h2 className="font-black text-2xl">Payment Settings</h2>
        <p className="text-sm text-[var(--corra-muted)]">
          Atur metode pembayaran sesi photobooth. Secret API key disimpan lewat
          Electron secure vault, bukan localStorage.
        </p>
      </div>

      {!vaultAvailable && (
        <div className="mb-5 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
          Secure vault hanya tersedia di Electron desktop. Browser preview tidak
          bisa menyimpan DOKU Secret Key atau Mayar API Key.
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Payment Provider
          </span>
          <select
            value={paymentConfig.provider}
            onChange={(event) =>
              updatePaymentConfig({
                provider: event.target.value as CorraPaymentProviderId,
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            {Object.entries(PAYMENT_PROVIDER_LABELS).map(([provider, label]) => (
              <option key={provider} value={provider}>
                {label}
              </option>
            ))}
          </select>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Session Price
          </span>
          <input
            value={paymentConfig.priceIdr}
            onChange={(event) =>
              updatePaymentConfig({
                priceIdr: Number(event.target.value),
              })
            }
            type="number"
            min={0}
            step={1000}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
          <span className="block text-xs text-[var(--corra-muted)]">
            Preview: {formatRupiah(paymentConfig.priceIdr)}
          </span>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Merchant Name
          </span>
          <input
            value={paymentConfig.merchantName}
            onChange={(event) =>
              updatePaymentConfig({
                merchantName: event.target.value,
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="flex items-center gap-3 rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3">
          <input
            checked={paymentConfig.requireOperatorConfirmation}
            onChange={(event) =>
              updatePaymentConfig({
                requireOperatorConfirmation: event.target.checked,
              })
            }
            type="checkbox"
            className="h-5 w-5"
          />
          <span className="text-sm font-bold">
            Require operator confirmation
          </span>
        </label>
      </div>

      {paymentConfig.provider === 'STATIC_QRIS' && (
        <div className="mt-6 rounded-3xl border border-[var(--corra-border)] bg-white/70 p-5">
          <h3 className="font-black text-lg">Static QRIS</h3>
          <p className="mt-1 text-sm text-[var(--corra-muted)]">
            Cocok untuk MVP. QRIS statis bisa pakai image URL/path sementara.
            File picker khusus QRIS masuk phase berikutnya.
          </p>

          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="space-y-2">
              <span className="text-xs font-black uppercase tracking-wider">
                QRIS Merchant Name
              </span>
              <input
                value={paymentConfig.staticQris.merchantName}
                onChange={(event) =>
                  updateStaticQris({
                    merchantName: event.target.value,
                  })
                }
                className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
              />
            </label>

            <label className="space-y-2 md:col-span-2">
              <span className="text-xs font-black uppercase tracking-wider">
                QRIS Image URL / Path
              </span>
              <input
                value={paymentConfig.staticQris.imageUrl}
                onChange={(event) =>
                  updateStaticQris({
                    imageUrl: event.target.value,
                  })
                }
                placeholder="https://... atau nanti corra-asset://qris/..."
                className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
              />
            </label>
          </div>
        </div>
      )}

      {paymentConfig.provider === 'DOKU_QRIS' && (
        <div className="mt-6 rounded-3xl border border-blue-100 bg-blue-50 p-5 text-blue-900">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <h3 className="font-black text-lg">DOKU Dynamic QRIS</h3>
              <p className="mt-1 text-sm">
                Dynamic QRIS butuh Client ID, Merchant ID, dan Secret Key.
              </p>
            </div>
            <SecretStatusBadge status={dokuSecretStatus} />
          </div>

          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="space-y-2">
              <span className="text-xs font-black uppercase tracking-wider">
                Environment
              </span>
              <select
                value={paymentConfig.doku.environment}
                onChange={(event) =>
                  updateDoku({
                    environment: event.target.value as CorraPaymentEnvironment,
                  })
                }
                className="w-full rounded-2xl border border-blue-200 bg-white px-4 py-3 text-sm outline-none"
              >
                <option value="sandbox">Sandbox</option>
                <option value="production">Production</option>
              </select>
            </label>

            <label className="space-y-2">
              <span className="text-xs font-black uppercase tracking-wider">
                DOKU Client ID
              </span>
              <input
                value={paymentConfig.doku.clientId}
                onChange={(event) =>
                  updateDoku({
                    clientId: event.target.value,
                  })
                }
                className="w-full rounded-2xl border border-blue-200 bg-white px-4 py-3 text-sm outline-none"
              />
            </label>

            <label className="space-y-2">
              <span className="text-xs font-black uppercase tracking-wider">
                DOKU Merchant ID
              </span>
              <input
                value={paymentConfig.doku.merchantId}
                onChange={(event) =>
                  updateDoku({
                    merchantId: event.target.value,
                  })
                }
                className="w-full rounded-2xl border border-blue-200 bg-white px-4 py-3 text-sm outline-none"
              />
            </label>

            <label className="space-y-2">
              <span className="text-xs font-black uppercase tracking-wider">
                DOKU Secret Key
              </span>
              <input
                value={dokuSecretInput}
                onChange={(event) => setDokuSecretInput(event.target.value)}
                disabled={!vaultAvailable}
                type="password"
                placeholder="Saved to Electron secure vault"
                className="w-full rounded-2xl border border-blue-200 bg-white px-4 py-3 text-sm outline-none disabled:opacity-60"
              />
            </label>
          </div>

          <div className="mt-4 flex flex-col sm:flex-row gap-3">
            <button
              type="button"
              onClick={handleSaveDokuSecret}
              disabled={!vaultAvailable || !dokuSecretInput.trim()}
              className="rounded-2xl bg-blue-700 px-5 py-3 text-sm font-black text-white disabled:opacity-50"
            >
              Save DOKU Secret Key
            </button>

            <button
              type="button"
              onClick={handleDeleteDokuSecret}
              disabled={!vaultAvailable || !dokuSecretStatus?.configured}
              className="rounded-2xl border border-blue-200 bg-white px-5 py-3 text-sm font-black text-blue-800 disabled:opacity-50"
            >
              Delete DOKU Secret Key
            </button>
          </div>
        </div>
      )}

      {paymentConfig.provider === 'MANUAL_CASH' && (
        <div className="mt-6 rounded-3xl border border-[var(--corra-border)] bg-white/70 p-5">
          <h3 className="font-black text-lg">Manual Cash / Operator</h3>
          <label className="mt-4 block space-y-2">
            <span className="text-xs font-black uppercase tracking-wider">
              Instructions
            </span>
            <textarea
              value={paymentConfig.manualCash.instructions}
              onChange={(event) =>
                updateManualCash({
                  instructions: event.target.value,
                })
              }
              className="min-h-24 w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
            />
          </label>
        </div>
      )}

      {paymentConfig.provider === 'MAYAR_CHECKOUT' && (
        <div className="mt-6 rounded-3xl border border-purple-100 bg-purple-50 p-5 text-purple-900">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <h3 className="font-black text-lg">Mayar Checkout</h3>
              <p className="mt-1 text-sm">
                Ini untuk pembayaran sesi booth, berbeda dari Mayar software license.
              </p>
            </div>
            <SecretStatusBadge status={mayarApiKeyStatus} />
          </div>

          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="space-y-2">
              <span className="text-xs font-black uppercase tracking-wider">
                Product ID
              </span>
              <input
                value={paymentConfig.mayarCheckout.productId}
                onChange={(event) =>
                  updateMayarCheckout({
                    productId: event.target.value,
                  })
                }
                className="w-full rounded-2xl border border-purple-200 bg-white px-4 py-3 text-sm outline-none"
              />
            </label>

            <label className="space-y-2">
              <span className="text-xs font-black uppercase tracking-wider">
                Checkout URL
              </span>
              <input
                value={paymentConfig.mayarCheckout.checkoutUrl}
                onChange={(event) =>
                  updateMayarCheckout({
                    checkoutUrl: event.target.value,
                  })
                }
                className="w-full rounded-2xl border border-purple-200 bg-white px-4 py-3 text-sm outline-none"
              />
            </label>

            <label className="space-y-2 md:col-span-2">
              <span className="text-xs font-black uppercase tracking-wider">
                Mayar Checkout API Key
              </span>
              <input
                value={mayarApiKeyInput}
                onChange={(event) => setMayarApiKeyInput(event.target.value)}
                disabled={!vaultAvailable}
                type="password"
                placeholder="Saved to Electron secure vault"
                className="w-full rounded-2xl border border-purple-200 bg-white px-4 py-3 text-sm outline-none disabled:opacity-60"
              />
            </label>
          </div>

          <div className="mt-4 flex flex-col sm:flex-row gap-3">
            <button
              type="button"
              onClick={handleSaveMayarApiKey}
              disabled={!vaultAvailable || !mayarApiKeyInput.trim()}
              className="rounded-2xl bg-purple-700 px-5 py-3 text-sm font-black text-white disabled:opacity-50"
            >
              Save Mayar API Key
            </button>

            <button
              type="button"
              onClick={handleDeleteMayarApiKey}
              disabled={!vaultAvailable || !mayarApiKeyStatus?.configured}
              className="rounded-2xl border border-purple-200 bg-white px-5 py-3 text-sm font-black text-purple-800 disabled:opacity-50"
            >
              Delete Mayar API Key
            </button>
          </div>
        </div>
      )}

      <div className="mt-5 flex flex-col sm:flex-row gap-3">
        <button
          type="button"
          onClick={() => setMessage('Payment settings saved locally.')}
          className="rounded-2xl bg-[var(--corra-primary)] px-5 py-3 text-sm font-black text-white"
        >
          Save Payment Settings
        </button>

        <button
          type="button"
          onClick={handleReset}
          className="rounded-2xl border border-[var(--corra-border)] bg-white px-5 py-3 text-sm font-black text-[var(--corra-text)]"
        >
          Reset Payment Settings
        </button>
      </div>

      {message && (
        <div className="mt-4 rounded-2xl border border-[var(--corra-border)] bg-white/70 p-3 text-xs font-bold text-[var(--corra-muted)]">
          {message}
        </div>
      )}
    </div>
  );
}
