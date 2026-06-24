import React from 'react';
import {
  getCheckMayarTransactionStatusUrl,
  getCreateMayarCheckoutUrl,
} from './mayar-payment-api';

export function PaymentProviderDiagnosticsPanel() {
  const mayarCreateUrl = getCreateMayarCheckoutUrl();
  const mayarCheckUrl = getCheckMayarTransactionStatusUrl();

  const rows = [
    ['Mayar create checkout', mayarCreateUrl],
    ['Mayar check status', mayarCheckUrl],
    ['DOKU QRIS', import.meta.env.VITE_CREATE_DOKU_QRIS_URL || ''],
    ['DOKU check status', import.meta.env.VITE_CHECK_DOKU_QRIS_STATUS_URL || ''],
  ];

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
        Payment Provider Diagnostics
      </p>
      <div className="mt-4 grid gap-2">
        {rows.map(([label, value]) => (
          <div key={label} className="rounded-2xl bg-white/10 p-3">
            <p className="text-xs font-black uppercase text-white">{label}</p>
            <p className={value ? 'mt-1 break-all text-xs font-bold text-emerald-100' : 'mt-1 text-xs font-bold text-red-200'}>
              {value || 'Not configured'}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
