import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothRuntimeProviders } from './BoothRuntimeProviders';
import { buildBoothModeHref } from './booth-mode-utils';

export function BoothFlowPreviewPanel() {
  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="mb-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Customer-Facing Flow
        </p>
        <h4 className="mt-1 text-xl font-black text-slate-950">
          Booth Flow Preview
        </h4>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Preview admin selalu menampilkan developer controls. Production booth
          mode menyembunyikan step navigation dari customer.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <a
            href={buildBoothModeHref({ dev: false })}
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Open Production Booth
          </a>

          <a
            href={buildBoothModeHref({ dev: true })}
            className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700"
          >
            Open Dev Booth
          </a>

          <a
            href={buildBoothModeHref({ dev: false, kiosk: true })}
            className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700"
          >
            Open Kiosk View
          </a>
        </div>
      </div>

      <BoothRuntimeProviders>
        <BoothCustomerScreen showDevNavigation />
      </BoothRuntimeProviders>
    </section>
  );
}
