import React, { useMemo, useState } from 'react';
import { checkMayarIntentStatus } from './mayar-payment-api';
import { createRealPaymentIntent } from './real-payment-api';
import {
  loadRealPaymentIntents,
  saveRealPaymentIntents,
  summarizeRealPaymentIntents,
  upsertRealPaymentIntent,
} from './real-payment-storage';
import type { RealPaymentIntent, RealPaymentProvider } from './real-payment-types';

type Props = {
  sessionId?: string;
  defaultAmount?: number;
};

export function RealPaymentRuntimePanel({ sessionId, defaultAmount = 25000 }: Props) {
  const [intents, setIntents] = useState(() => loadRealPaymentIntents());
  const [provider, setProvider] = useState<RealPaymentProvider>('MAYAR_CHECKOUT');
  const [amount, setAmount] = useState(defaultAmount);
  const [customerName, setCustomerName] = useState('Corra Booth Customer');
  const [customerEmail, setCustomerEmail] = useState('');
  const [isBusy, setIsBusy] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const summary = useMemo(() => summarizeRealPaymentIntents(intents), [intents]);
  const recent = intents.slice(-5).reverse();

  const refresh = () => {
    setIntents(loadRealPaymentIntents());
    setMessage('Payment intents refreshed.');
    setError('');
  };

  const saveAndSet = (next: RealPaymentIntent[]) => {
    saveRealPaymentIntents(next);
    setIntents(next);
  };

  const createIntent = async () => {
    setIsBusy(true);
    setMessage('');
    setError('');

    try {
      const intent = await createRealPaymentIntent({
        sessionId: sessionId || `manual-${Date.now()}`,
        provider,
        amount,
        currency: 'IDR',
        description: 'Corra Booth Photo Session',
        customer: {
          name: customerName,
          email: customerEmail || undefined,
        },
      });

      const next = upsertRealPaymentIntent(intent);
      setIntents(next);
      setMessage('Payment intent created.');

      if (intent.checkoutUrl) {
        window.open(intent.checkoutUrl, '_blank', 'noopener,noreferrer');
      }
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Create payment failed.');
    } finally {
      setIsBusy(false);
    }
  };

  const markPaid = (intent: RealPaymentIntent) => {
    const nextIntent: RealPaymentIntent = {
      ...intent,
      status: 'paid',
      paidAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const next = upsertRealPaymentIntent(nextIntent);
    setIntents(next);
    setMessage('Intent marked paid locally.');
  };

  const checkStatus = async (intent: RealPaymentIntent) => {
    setIsBusy(true);
    setMessage('');
    setError('');

    try {
      if (intent.provider !== 'MAYAR_CHECKOUT') {
        setMessage('Status check currently implemented for Mayar only.');
        return;
      }

      const nextIntent = await checkMayarIntentStatus(intent);
      const next = upsertRealPaymentIntent(nextIntent);
      setIntents(next);
      setMessage(`Status: ${nextIntent.status}`);
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Status check failed.');
    } finally {
      setIsBusy(false);
    }
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Real Payment Runtime
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Create checkout, open payment URL, poll status, and keep local payment intents.
          </p>
        </div>

        <button
          type="button"
          onClick={refresh}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
        >
          Refresh
        </button>
      </div>

      <div className="mt-4 grid gap-3 md:grid-cols-4">
        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Total</p>
          <p className="mt-1 text-2xl font-black text-white">{summary.total}</p>
        </div>
        <div className="rounded-2xl bg-amber-500/20 p-3">
          <p className="text-xs font-black uppercase text-amber-100">Pending</p>
          <p className="mt-1 text-2xl font-black text-white">{summary.pending}</p>
        </div>
        <div className="rounded-2xl bg-emerald-500/20 p-3">
          <p className="text-xs font-black uppercase text-emerald-100">Paid</p>
          <p className="mt-1 text-2xl font-black text-white">{summary.paid}</p>
        </div>
        <div className="rounded-2xl bg-red-500/20 p-3">
          <p className="text-xs font-black uppercase text-red-100">Failed/Expired</p>
          <p className="mt-1 text-2xl font-black text-white">{summary.failed + summary.expired}</p>
        </div>
      </div>

      <div className="mt-4 grid gap-3 lg:grid-cols-4">
        <select
          value={provider}
          onChange={(event) => setProvider(event.target.value as RealPaymentProvider)}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
        >
          <option value="MAYAR_CHECKOUT">Mayar Checkout</option>
          <option value="DOKU_QRIS">DOKU QRIS</option>
          <option value="STATIC_QRIS">Static QRIS</option>
          <option value="MANUAL_CASH">Manual Cash</option>
        </select>

        <input
          type="number"
          value={amount}
          onChange={(event) => setAmount(Number(event.target.value))}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
          placeholder="Amount"
        />

        <input
          value={customerName}
          onChange={(event) => setCustomerName(event.target.value)}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
          placeholder="Customer name"
        />

        <input
          value={customerEmail}
          onChange={(event) => setCustomerEmail(event.target.value)}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
          placeholder="Customer email optional"
        />
      </div>

      <button
        type="button"
        onClick={() => void createIntent()}
        disabled={isBusy}
        className="mt-3 rounded-2xl bg-white px-4 py-3 text-xs font-black text-slate-950 disabled:opacity-40"
      >
        {isBusy ? 'Processing...' : 'Create Payment Intent'}
      </button>

      {message && (
        <div className="mt-4 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">
          {message}
        </div>
      )}

      {error && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          {error}
        </div>
      )}

      <div className="mt-4 grid gap-2">
        {recent.map((intent) => (
          <div key={intent.id} className="rounded-2xl bg-white/10 p-3">
            <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                  {intent.provider} · {intent.status} · Rp {intent.amount.toLocaleString('id-ID')}
                </p>
                <p className="mt-1 break-all text-[11px] font-bold text-white/45">
                  session: {intent.sessionId}
                </p>
                {intent.checkoutUrl && (
                  <p className="mt-1 break-all text-[11px] font-bold text-white/45">
                    {intent.checkoutUrl}
                  </p>
                )}
                {intent.error && (
                  <p className="mt-1 text-[11px] font-bold text-red-200">{intent.error}</p>
                )}
              </div>

              <div className="flex flex-wrap gap-2">
                {intent.checkoutUrl && (
                  <a
                    href={intent.checkoutUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
                  >
                    Open
                  </a>
                )}
                <button
                  type="button"
                  onClick={() => void checkStatus(intent)}
                  disabled={isBusy}
                  className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white disabled:opacity-40"
                >
                  Check
                </button>
                <button
                  type="button"
                  onClick={() => markPaid(intent)}
                  className="rounded-2xl border border-emerald-300/30 bg-emerald-500/20 px-3 py-2 text-xs font-black text-emerald-100"
                >
                  Mark Paid
                </button>
              </div>
            </div>
          </div>
        ))}

        {recent.length === 0 && (
          <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">
            No real payment intents yet.
          </div>
        )}
      </div>
    </section>
  );
}
