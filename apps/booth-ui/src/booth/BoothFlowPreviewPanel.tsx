import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothFlowProvider } from './BoothFlowProvider';

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
          Fondasi layar customer. Nanti flow ini dipisah dari admin hardware page
          dan dijadikan mode booth full-screen.
        </p>
      </div>

      <BoothFlowProvider>
        <BoothCustomerScreen />
      </BoothFlowProvider>
    </section>
  );
}
