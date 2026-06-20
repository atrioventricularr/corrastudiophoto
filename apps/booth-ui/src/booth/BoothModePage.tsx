import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothRuntimeProviders } from './BoothRuntimeProviders';

function goToAdminMode() {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.delete('mode');
  url.searchParams.delete('booth');
  url.hash = '';

  window.location.href = url.toString();
}

export function BoothModePage() {
  return (
    <main className="min-h-screen bg-slate-950 p-4 text-white sm:p-6 lg:p-8">
      <div className="mx-auto flex max-w-7xl flex-col gap-4">
        <header className="flex flex-col gap-3 rounded-[2rem] border border-white/10 bg-white/5 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.25em] text-white/40">
              Corra Booth
            </p>
            <h1 className="mt-1 text-2xl font-black">
              Customer Booth Mode
            </h1>
            <p className="mt-1 text-sm font-semibold text-white/50">
              Full-page customer-facing flow. Buka via <code>?mode=booth</code>{' '}
              atau <code>#/booth</code>.
            </p>
          </div>

          <button
            type="button"
            onClick={goToAdminMode}
            className="rounded-2xl bg-white px-4 py-3 text-xs font-black text-slate-950"
          >
            Back to Admin
          </button>
        </header>

        <BoothRuntimeProviders>
          <BoothCustomerScreen />
        </BoothRuntimeProviders>
      </div>
    </main>
  );
}
