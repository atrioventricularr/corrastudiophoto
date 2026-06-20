import React from 'react';
import { usePaymentSettings } from '../payments/PaymentSettingsProvider';
import { useBoothFlow } from './BoothFlowProvider';

function formatIdr(value: unknown) {
  const numberValue =
    typeof value === 'number'
      ? value
      : typeof value === 'string'
        ? Number(value.replace(/[^0-9.-]+/g, ''))
        : 0;

  if (!Number.isFinite(numberValue) || numberValue <= 0) {
    return 'Price not set';
  }

  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(numberValue);
}

function readFirstString(
  settings: Record<string, unknown>,
  keys: string[],
  fallback: string,
) {
  for (const key of keys) {
    const value = settings[key];

    if (typeof value === 'string' && value.trim()) {
      return value;
    }
  }

  return fallback;
}

function readFirstValue(
  settings: Record<string, unknown>,
  keys: string[],
): unknown {
  for (const key of keys) {
    const value = settings[key];

    if (value !== undefined && value !== null && value !== '') {
      return value;
    }
  }

  return undefined;
}

function getPaymentSettingsObject(context: unknown): Record<string, unknown> {
  const value = context as {
    settings?: Record<string, unknown>;
    paymentSettings?: Record<string, unknown>;
    payment?: Record<string, unknown>;
    config?: Record<string, unknown>;
  };

  return (
    value.settings ||
    value.paymentSettings ||
    value.payment ||
    value.config ||
    {}
  );
}

export function BoothPaymentStep() {
  const {
    paymentStatus,
    markPaymentPending,
    markPaymentConfirmed,
    markPaymentFailed,
    setStep,
  } = useBoothFlow();
  const paymentContext = usePaymentSettings() as unknown;
  const settings = getPaymentSettingsObject(paymentContext);

  const merchantName = readFirstString(
    settings,
    [
      'merchantName',
      'businessName',
      'storeName',
      'brandName',
      'displayName',
    ],
    'Corra Booth',
  );

  const provider = readFirstString(
    settings,
    [
      'provider',
      'activeProvider',
      'paymentProvider',
      'defaultProvider',
      'method',
    ],
    'Payment Provider',
  );

  const priceValue = readFirstValue(settings, [
    'sessionPrice',
    'sessionPriceIdr',
    'photoSessionPrice',
    'price',
    'priceAmount',
    'amount',
    'amountIdr',
    'basePrice',
    'defaultAmount',
  ]);

  const staticQrisImage = readFirstString(
    settings,
    [
      'staticQrisDataUrl',
      'qrisDataUrl',
      'qrisImageUrl',
      'staticQrisImageUrl',
      'qrisAssetUrl',
      'staticQrisUrl',
      'qrisUrl',
    ],
    '',
  );

  const handleConfirmPayment = () => {
    markPaymentConfirmed();
  };

  const handleSetPending = () => {
    markPaymentPending();
  };

  const handleSetFailed = () => {
    markPaymentFailed();
  };

  return (
    <div className="mt-4 grid gap-6 lg:grid-cols-[0.9fr_1.1fr] lg:items-stretch">
      <aside className="rounded-[2rem] bg-white p-6 text-slate-950">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-blue-500">
          Payment
        </p>

        <h4 className="mt-3 text-5xl font-black leading-none">
          Complete Payment
        </h4>

        <p className="mt-4 text-sm font-bold leading-relaxed text-slate-600">
          Selesaikan pembayaran untuk membuka sesi camera. Untuk development,
          tombol confirm masih manual sampai payment gate customer disambungkan
          ke transaksi real-time.
        </p>

        <div className="mt-6 grid gap-3">
          <div className="rounded-3xl bg-slate-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Merchant
            </p>
            <p className="mt-2 text-xl font-black text-slate-950">
              {merchantName}
            </p>
          </div>

          <div className="rounded-3xl bg-blue-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
              Session Price
            </p>
            <p className="mt-2 text-3xl font-black text-blue-700">
              {formatIdr(priceValue)}
            </p>
          </div>

          <div className="rounded-3xl bg-emerald-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
              Active Provider
            </p>
            <p className="mt-2 text-lg font-black text-emerald-800">
              {provider}
            </p>
          </div>

          <div className="rounded-3xl bg-violet-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-violet-500">
              Payment Status
            </p>
            <p className="mt-2 text-lg font-black uppercase text-violet-800">
              {paymentStatus}
            </p>
          </div>
        </div>

        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setStep('welcome')}
            className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            Back
          </button>

          <button
            type="button"
            onClick={handleConfirmPayment}
            className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
          >
            Confirm Payment
          </button>
        </div>

        <div className="mt-3 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={handleSetPending}
            className="rounded-3xl border border-blue-200 bg-blue-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-blue-700"
          >
            Mark Pending
          </button>

          <button
            type="button"
            onClick={handleSetFailed}
            className="rounded-3xl border border-red-200 bg-red-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-red-700"
          >
            Mark Failed
          </button>
        </div>
      </aside>

      <section className="rounded-[2rem] border border-white/10 bg-white/10 p-6">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
          Payment Display
        </p>

        {staticQrisImage ? (
          <div className="mt-4 rounded-[2rem] bg-white p-6 text-center text-slate-950">
            <p className="text-sm font-black uppercase tracking-[0.2em] text-slate-400">
              Scan QRIS
            </p>

            <img
              src={staticQrisImage}
              alt="Static QRIS"
              className="mx-auto mt-5 max-h-[360px] rounded-3xl border border-slate-200 bg-white object-contain"
            />

            <p className="mt-4 text-sm font-bold text-slate-500">
              Setelah pembayaran berhasil, tekan Confirm Payment.
            </p>
          </div>
        ) : (
          <div className="mt-4 flex min-h-[420px] flex-col items-center justify-center rounded-[2rem] border border-dashed border-white/20 bg-black/20 p-6 text-center">
            <p className="text-5xl font-black">QRIS</p>
            <p className="mt-3 max-w-md text-sm font-semibold text-white/60">
              Static QRIS belum terdeteksi dari payment settings. Untuk sekarang
              customer bisa dikonfirmasi manual lewat tombol Confirm Payment.
            </p>
          </div>
        )}

        <div className="mt-4 rounded-3xl bg-black/20 p-4">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Dev Note
          </p>
          <p className="mt-2 text-sm font-semibold text-white/60">
            Next phase akan bikin payment gate state yang bisa menunggu status
            transaksi confirmed sebelum lanjut ke camera.
          </p>
        </div>
      </section>
    </div>
  );
}
