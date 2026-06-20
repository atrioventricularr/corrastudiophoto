import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothRuntimeProviders } from './BoothRuntimeProviders';
import {
  buildBoothModeHref,
  getBoothUrlMode,
  goToAdminMode,
} from './booth-mode-utils';

export function BoothModePage() {
  const {
    isDevMode,
    isKioskMode,
  } = getBoothUrlMode();

  return (
    <main
      className={`min-h-screen bg-slate-950 text-white ${
        isKioskMode ? 'p-0' : 'p-4 sm:p-6 lg:p-8'
      }`}
    >
      <div className={`mx-auto flex flex-col gap-4 ${isKioskMode ? 'max-w-none' : 'max-w-7xl'}`}>
        {!isKioskMode && (
          <header className="flex flex-col gap-3 rounded-[2rem] border border-white/10 bg-white/5 p-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.25em] text-white/40">
                Corra Booth
              </p>
              <h1 className="mt-1 text-2xl font-black">
                Customer Booth Mode
              </h1>
              <p className="mt-1 text-sm font-semibold text-white/50">
                {isDevMode
                  ? 'Developer booth mode with step navigation enabled.'
                  : 'Production booth mode with customer navigation locked.'}
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              {isDevMode ? (
                <a
                  href={buildBoothModeHref({ dev: false })}
                  className="rounded-2xl border border-white/15 bg-white/10 px-4 py-3 text-xs font-black text-white"
                >
                  Production Mode
                </a>
              ) : (
                <a
                  href={buildBoothModeHref({ dev: true })}
                  className="rounded-2xl border border-white/15 bg-white/10 px-4 py-3 text-xs font-black text-white"
                >
                  Dev Mode
                </a>
              )}

              <a
                href={buildBoothModeHref({ dev: isDevMode, kiosk: true })}
                className="rounded-2xl border border-white/15 bg-white/10 px-4 py-3 text-xs font-black text-white"
              >
                Kiosk View
              </a>

              {isDevMode && (
                <button
                  type="button"
                  onClick={goToAdminMode}
                  className="rounded-2xl bg-white px-4 py-3 text-xs font-black text-slate-950"
                >
                  Back to Admin
                </button>
              )}
            </div>
          </header>
        )}

        <BoothRuntimeProviders>
          <BoothCustomerScreen
            showDevNavigation={isDevMode}
            showHeader={!isKioskMode}
          />
        </BoothRuntimeProviders>
      </div>
    </main>
  );
}
