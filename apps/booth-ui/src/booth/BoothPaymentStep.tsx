import React from 'react';
import { usePaymentSettings } from '../payments/PaymentSettingsProvider';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';
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

function getPaymentStatusStyle(status: string) {
  if (status === 'confirmed') {
    return {
      card: 'bg-emerald-50',
      label: 'text-emerald-500',
      text: 'text-emerald-800',
      badge: 'bg-emerald-600',
    };
  }

  if (status === 'pending') {
    return {
      card: 'bg-blue-50',
      label: 'text-blue-500',
      text: 'text-blue-800',
      badge: 'bg-blue-600',
    };
  }

  if (status === 'failed') {
    return {
      card: 'bg-red-50',
      label: 'text-red-500',
      text: 'text-red-800',
      badge: 'bg-red-600',
    };
  }

  return {
    card: 'bg-violet-50',
    label: 'text-violet-500',
    text: 'text-violet-800',
    badge: 'bg-violet-600',
  };
}

export function BoothPaymentStep() {
  const {
    session,
    paymentStatus,
    markPaymentPending,
    markPaymentConfirmed,
    markPaymentFailed,
    setStep,
  } = useBoothFlow();

  const {
    recordBoothEvent,
  } = useBoothLifecycleLogger();

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

  const statusStyle = getPaymentStatusStyle(paymentStatus);

  const handleStartPayment = () => {
    markPaymentPending();

    recordBoothEvent({
      type: 'payment_pending',
      summary: 'Customer started payment flow.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'pending',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });
  };

  const handleConfirmPayment = () => {
    recordBoothEvent({
      type: 'payment_confirmed',
      summary: 'Payment manually confirmed from booth payment screen.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'confirmed',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });

    markPaymentConfirmed();
  };

  const handleFailPayment = () => {
    recordBoothEvent({
      type: 'payment_failed',
      summary: 'Payment manually marked as failed from booth payment screen.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'failed',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });

    markPaymentFailed();
  };

  const handleRetryPayment = () => {
    markPaymentPending();

    recordBoothEvent({
      type: 'payment_pending',
      summary: 'Customer retried payment flow.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'pending',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });
  };

  return (
    <div className="mt-4 grid gap-6 lg:grid-cols-[0.9fr_1.1fr] lg:items-stretch">
      <aside className="rounded-[2rem] bg-white p-6 text-slate-950">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.25em] text-blue-500">
              Payment
            </p>

            <h4 className="mt-3 text-5xl font-black leading-none">
              Complete Payment
            </h4>
          </div>

          <span
            className={`rounded-full px-3 py-1 text-xs font-black uppercase text-white ${statusStyle.badge}`}
          >
            {paymentStatus}
          </span>
        </div>

        <p className="mt-4 text-sm font-bold leading-relaxed text-slate-600">
          Selesaikan pembayaran untuk membuka sesi camera. Status payment
          sekarang punya state idle, pending, confirmed, dan failed.
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

          <div className={`rounded-3xl p-4 ${statusStyle.card}`}>
            <p className={`text-xs font-black uppercase tracking-[0.2em] ${statusStyle.label}`}>
              Payment Status
            </p>
            <p className={`mt-2 text-lg font-black uppercase ${statusStyle.text}`}>
              {paymentStatus}
            </p>
          </div>
        </div>

        {paymentStatus === 'idle' && (
          <div className="mt-6 rounded-3xl bg-violet-50 p-4">
            <p className="text-sm font-black text-violet-900">
              Ready to start payment.
            </p>
            <p className="mt-1 text-xs font-bold text-violet-700">
              Customer akan masuk ke waiting state setelah menekan Start
              Payment.
            </p>
          </div>
        )}

        {paymentStatus === 'pending' && (
          <div className="mt-6 rounded-3xl bg-blue-50 p-4">
            <div className="flex items-center gap-3">
              <div className="h-4 w-4 animate-pulse rounded-full bg-blue-600" />
              <p className="text-sm font-black text-blue-900">
                Waiting for payment confirmation...
              </p>
            </div>
            <p className="mt-2 text-xs font-bold text-blue-700">
              Untuk Static QRIS/manual mode, operator/customer bisa confirm
              manual. Untuk DOKU nanti state ini bisa dipolling dari transaction
              status.
            </p>
          </div>
        )}

        {paymentStatus === 'failed' && (
          <div className="mt-6 rounded-3xl bg-red-50 p-4">
            <p className="text-sm font-black text-red-900">
              Payment failed or cancelled.
            </p>
            <p className="mt-1 text-xs font-bold text-red-700">
              Customer bisa retry payment atau kembali ke welcome.
            </p>
          </div>
        )}

        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setStep('welcome')}
            className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            Back
          </button>

          {paymentStatus === 'idle' && (
            <button
              type="button"
              onClick={handleStartPayment}
              className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
            >
              Start Payment
            </button>
          )}

          {paymentStatus === 'pending' && (
            <button
              type="button"
              onClick={handleConfirmPayment}
              className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
            >
              Confirm Payment
            </button>
          )}

          {paymentStatus === 'failed' && (
            <button
              type="button"
              onClick={handleRetryPayment}
              className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
            >
              Retry Payment
            </button>
          )}
        </div>

        {paymentStatus === 'pending' && (
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <button
              type="button"
              onClick={handleFailPayment}
              className="rounded-3xl border border-red-200 bg-red-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-red-700"
            >
              Mark Failed
            </button>

            <button
              type="button"
              onClick={handleRetryPayment}
              className="rounded-3xl border border-blue-200 bg-blue-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-blue-700"
            >
              Restart Waiting
            </button>
          </div>
        )}
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
              customer bisa dikonfirmasi manual lewat tombol Start Payment lalu
              Confirm Payment.
            </p>
          </div>
        )}

        <div className="mt-4 rounded-3xl bg-black/20 p-4">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Payment Gate
          </p>
          <p className="mt-2 text-sm font-semibold text-white/60">
            Status pending adalah tempat nanti DOKU polling / webhook / admin
            confirmation disambungkan. Saat confirmed, flow otomatis masuk ke
            Camera step.
          </p>
        </div>
      </section>
    </div>
  );
}
