#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 8A1 Payment Settings Foundation"
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

[ -f "apps/booth-ui/src/main.tsx" ] || fail "main.tsx not found."
[ -f "apps/booth-ui/src/components/AdminPanel.tsx" ] || fail "AdminPanel.tsx not found."

echo ""
echo "Writing payment types..."

write_file "apps/booth-ui/src/payments/types.ts" <<'TS'
export type CorraPaymentProviderId =
  | 'STATIC_QRIS'
  | 'DOKU_QRIS'
  | 'MANUAL_CASH'
  | 'MAYAR_CHECKOUT';

export type CorraPaymentEnvironment = 'sandbox' | 'production';

export type CorraPaymentConfig = {
  provider: CorraPaymentProviderId;
  priceIdr: number;
  currency: 'IDR';
  merchantName: string;
  requireOperatorConfirmation: boolean;
  staticQris: {
    imageUrl: string;
    merchantName: string;
    notes: string;
  };
  doku: {
    environment: CorraPaymentEnvironment;
    clientId: string;
    merchantId: string;
    isCredentialConfigured: boolean;
  };
  mayarCheckout: {
    productId: string;
    checkoutUrl: string;
    isConfigured: boolean;
  };
  manualCash: {
    instructions: string;
  };
  updatedAt: string | null;
};

export type CorraPaymentSettingsContextValue = {
  paymentConfig: CorraPaymentConfig;
  setPaymentConfig: (nextConfig: CorraPaymentConfig) => void;
  updatePaymentConfig: (patch: Partial<CorraPaymentConfig>) => void;
  resetPaymentConfig: () => void;
};
TS

echo ""
echo "Writing default payment config..."

write_file "apps/booth-ui/src/payments/default-payment-config.ts" <<'TS'
import type { CorraPaymentConfig } from './types';

export const DEFAULT_CORRA_PAYMENT_CONFIG: CorraPaymentConfig = {
  provider: 'STATIC_QRIS',
  priceIdr: 35000,
  currency: 'IDR',
  merchantName: 'Corra Studio',
  requireOperatorConfirmation: true,
  staticQris: {
    imageUrl: '',
    merchantName: 'Corra Studio',
    notes: 'Scan QRIS, lalu tunjukkan bukti pembayaran ke operator.',
  },
  doku: {
    environment: 'sandbox',
    clientId: '',
    merchantId: '',
    isCredentialConfigured: false,
  },
  mayarCheckout: {
    productId: '',
    checkoutUrl: '',
    isConfigured: false,
  },
  manualCash: {
    instructions: 'Bayar langsung ke operator sebelum sesi foto dimulai.',
  },
  updatedAt: null,
};
TS

echo ""
echo "Writing local payment config storage..."

write_file "apps/booth-ui/src/payments/local-payment-config.ts" <<'TS'
import { DEFAULT_CORRA_PAYMENT_CONFIG } from './default-payment-config';
import type { CorraPaymentConfig } from './types';

const STORAGE_KEY = 'corra.paymentConfig.v1';

export function loadLocalPaymentConfig(): CorraPaymentConfig {
  if (typeof window === 'undefined') {
    return DEFAULT_CORRA_PAYMENT_CONFIG;
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return DEFAULT_CORRA_PAYMENT_CONFIG;
    }

    const parsed = JSON.parse(raw) as Partial<CorraPaymentConfig>;

    return {
      ...DEFAULT_CORRA_PAYMENT_CONFIG,
      ...parsed,
      staticQris: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.staticQris,
        ...(parsed.staticQris || {}),
      },
      doku: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.doku,
        ...(parsed.doku || {}),
      },
      mayarCheckout: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.mayarCheckout,
        ...(parsed.mayarCheckout || {}),
      },
      manualCash: {
        ...DEFAULT_CORRA_PAYMENT_CONFIG.manualCash,
        ...(parsed.manualCash || {}),
      },
    };
  } catch {
    return DEFAULT_CORRA_PAYMENT_CONFIG;
  }
}

export function saveLocalPaymentConfig(config: CorraPaymentConfig): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(
    STORAGE_KEY,
    JSON.stringify({
      ...config,
      updatedAt: new Date().toISOString(),
    }),
  );
}

export function clearLocalPaymentConfig(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(STORAGE_KEY);
}
TS

echo ""
echo "Writing PaymentSettingsProvider..."

write_file "apps/booth-ui/src/payments/PaymentSettingsProvider.tsx" <<'TSX'
import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { DEFAULT_CORRA_PAYMENT_CONFIG } from './default-payment-config';
import {
  clearLocalPaymentConfig,
  loadLocalPaymentConfig,
  saveLocalPaymentConfig,
} from './local-payment-config';
import type {
  CorraPaymentConfig,
  CorraPaymentSettingsContextValue,
} from './types';

const PaymentSettingsContext =
  createContext<CorraPaymentSettingsContextValue | null>(null);

type PaymentSettingsProviderProps = {
  children: ReactNode;
};

export function PaymentSettingsProvider({
  children,
}: PaymentSettingsProviderProps) {
  const [paymentConfig, setPaymentConfigState] = useState<CorraPaymentConfig>(
    () => loadLocalPaymentConfig(),
  );

  useEffect(() => {
    saveLocalPaymentConfig(paymentConfig);
  }, [paymentConfig]);

  const value = useMemo<CorraPaymentSettingsContextValue>(() => {
    return {
      paymentConfig,
      setPaymentConfig: setPaymentConfigState,
      updatePaymentConfig: (patch) => {
        setPaymentConfigState((current) => ({
          ...current,
          ...patch,
          staticQris: {
            ...current.staticQris,
            ...(patch.staticQris || {}),
          },
          doku: {
            ...current.doku,
            ...(patch.doku || {}),
          },
          mayarCheckout: {
            ...current.mayarCheckout,
            ...(patch.mayarCheckout || {}),
          },
          manualCash: {
            ...current.manualCash,
            ...(patch.manualCash || {}),
          },
        }));
      },
      resetPaymentConfig: () => {
        clearLocalPaymentConfig();
        setPaymentConfigState(DEFAULT_CORRA_PAYMENT_CONFIG);
      },
    };
  }, [paymentConfig]);

  return (
    <PaymentSettingsContext.Provider value={value}>
      {children}
    </PaymentSettingsContext.Provider>
  );
}

export function usePaymentSettings(): CorraPaymentSettingsContextValue {
  const context = useContext(PaymentSettingsContext);

  if (!context) {
    throw new Error('usePaymentSettings must be used inside PaymentSettingsProvider');
  }

  return context;
}
TSX

write_file "apps/booth-ui/src/payments/index.ts" <<'TS'
export * from './types';
export * from './default-payment-config';
export * from './local-payment-config';
export * from './PaymentSettingsProvider';
TS

echo ""
echo "Writing PaymentSettingsPanel..."

write_file "apps/booth-ui/src/components/admin/PaymentSettingsPanel.tsx" <<'TSX'
import React, { useState } from 'react';
import {
  usePaymentSettings,
  type CorraPaymentEnvironment,
  type CorraPaymentProviderId,
} from '../../payments';

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

export default function PaymentSettingsPanel() {
  const { paymentConfig, updatePaymentConfig, resetPaymentConfig } =
    usePaymentSettings();
  const [message, setMessage] = useState('');

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

  const handleReset = () => {
    resetPaymentConfig();
    setMessage('Payment settings reset to default.');
  };

  return (
    <div className="rounded-3xl border border-[var(--corra-border)] bg-[var(--corra-surface)] p-6 text-[var(--corra-text)]">
      <div className="mb-5">
        <h2 className="font-black text-2xl">Payment Settings</h2>
        <p className="text-sm text-[var(--corra-muted)]">
          Atur metode pembayaran sesi photobooth. Secret API key akan masuk ke
          secure desktop vault pada phase berikutnya.
        </p>
      </div>

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
            Cocok untuk MVP. Customer upload/isi path QRIS statis, lalu operator
            confirm manual.
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

            <label className="space-y-2 md:col-span-2">
              <span className="text-xs font-black uppercase tracking-wider">
                Payment Instructions
              </span>
              <textarea
                value={paymentConfig.staticQris.notes}
                onChange={(event) =>
                  updateStaticQris({
                    notes: event.target.value,
                  })
                }
                className="min-h-24 w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
              />
            </label>
          </div>
        </div>
      )}

      {paymentConfig.provider === 'DOKU_QRIS' && (
        <div className="mt-6 rounded-3xl border border-blue-100 bg-blue-50 p-5 text-blue-900">
          <h3 className="font-black text-lg">DOKU Dynamic QRIS</h3>
          <p className="mt-1 text-sm">
            Dynamic QRIS butuh credential DOKU dan webhook/status check. Secret
            key tidak disimpan di React. Phase 8A2 akan menambahkan secure
            credential vault via Electron.
          </p>

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

            <div className="rounded-2xl border border-blue-200 bg-white p-4 text-sm">
              <p className="font-black">Secret Key</p>
              <p className="mt-1 text-blue-700">
                Secure input coming in Phase 8A2.
              </p>
            </div>
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
          <h3 className="font-black text-lg">Mayar Checkout</h3>
          <p className="mt-1 text-sm">
            Ini berbeda dari Mayar software license. Mode ini untuk pembayaran
            sesi booth via checkout page.
          </p>

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
TSX

echo ""
echo "Patching main.tsx to add PaymentSettingsProvider..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/main.tsx")
text = path.read_text()

if "PaymentSettingsProvider" not in text:
    text = text.replace(
        "import { BrandThemeProvider, ThemedBackground } from './branding';",
        "import { BrandThemeProvider, ThemedBackground } from './branding';\nimport { PaymentSettingsProvider } from './payments';"
    )

if "<PaymentSettingsProvider>" not in text:
    text = text.replace(
        """<BrandThemeProvider>
      <ThemedBackground />
      <App />
    </BrandThemeProvider>""",
        """<BrandThemeProvider>
      <PaymentSettingsProvider>
        <ThemedBackground />
        <App />
      </PaymentSettingsProvider>
    </BrandThemeProvider>"""
    )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/main.tsx")
PY

echo ""
echo "Patching AdminPanel..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

if "PaymentSettingsPanel" not in text:
    if "AdminCredentialPanel from './admin/AdminCredentialPanel';" in text:
        text = text.replace(
            "import AdminCredentialPanel from './admin/AdminCredentialPanel';",
            "import AdminCredentialPanel from './admin/AdminCredentialPanel';\nimport PaymentSettingsPanel from './admin/PaymentSettingsPanel';"
        )
    else:
        lines = text.splitlines()
        insert_at = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = i + 1
        lines.insert(insert_at, "import PaymentSettingsPanel from './admin/PaymentSettingsPanel';")
        text = "\n".join(lines) + "\n"

if "<PaymentSettingsPanel />" not in text:
    if "<AdminCredentialPanel />" in text:
        text = text.replace(
            "<AdminCredentialPanel />",
            "<AdminCredentialPanel />\n        <div className=\"mt-6\">\n          <PaymentSettingsPanel />\n        </div>",
            1
        )
    elif "<BrandAppearancePanel />" in text:
        text = text.replace(
            "<BrandAppearancePanel />",
            "<BrandAppearancePanel />\n        <div className=\"mt-6\">\n          <PaymentSettingsPanel />\n        </div>",
            1
        )
    else:
        marker = "      {/* Main double column form container */}"
        if marker not in text:
            raise SystemExit("Could not find insertion point in AdminPanel.tsx")
        text = text.replace(
            marker,
            "      <div className=\"mt-6\">\n        <PaymentSettingsPanel />\n      </div>\n\n" + marker,
            1
        )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/components/AdminPanel.tsx")
PY

echo ""
echo "Writing docs..."

write_file "docs/phase-8a1-payment-settings-foundation.md" <<'MD'
# Phase 8A1 - Payment Settings Foundation

## Added

- Payment settings model
- PaymentSettingsProvider
- PaymentSettingsPanel in Admin Panel

## Providers

- Static QRIS PNG
- DOKU Dynamic QRIS
- Manual Cash / Operator
- Mayar Checkout

## Important

This phase stores non-secret payment settings locally for development.
DOKU secret key and other sensitive payment credentials should be stored through Electron secure credential vault in Phase 8A2.
MD

echo ""
echo "Verifying..."

[ -f "apps/booth-ui/src/payments/index.ts" ] || fail "Missing payments index."
[ -f "apps/booth-ui/src/components/admin/PaymentSettingsPanel.tsx" ] || fail "Missing PaymentSettingsPanel."
grep -q "PaymentSettingsProvider" apps/booth-ui/src/main.tsx || fail "main.tsx missing PaymentSettingsProvider."
grep -q "PaymentSettingsPanel" apps/booth-ui/src/components/AdminPanel.tsx || fail "AdminPanel missing PaymentSettingsPanel."

echo ""
echo "========================================"
echo " Phase 8A1 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  pnpm --filter @corra/booth-ui dev -- --host 0.0.0.0 --port 5173"
echo "  git add ."
echo "  git commit -m \"feat: add payment settings foundation\""
echo "  git push origin main"
echo ""
