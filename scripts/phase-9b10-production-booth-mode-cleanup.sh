#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B10 - Production Booth Mode Cleanup"
echo "========================================"

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/booth-mode-utils.ts <<'TS'
export function getBoothUrlMode() {
  if (typeof window === 'undefined') {
    return {
      isBoothMode: false,
      isDevMode: false,
      isKioskMode: false,
    };
  }

  const url = new URL(window.location.href);
  const hash = window.location.hash.toLowerCase();
  const pathname = window.location.pathname.toLowerCase();

  const isBoothMode =
    url.searchParams.get('mode') === 'booth' ||
    url.searchParams.get('booth') === '1' ||
    hash === '#/booth' ||
    hash === '#booth' ||
    pathname.endsWith('/booth');

  const isDevMode =
    url.searchParams.get('dev') === '1' ||
    url.searchParams.get('boothDev') === '1' ||
    hash.includes('booth-dev');

  const isKioskMode =
    url.searchParams.get('kiosk') === '1' ||
    url.searchParams.get('fullscreen') === '1';

  return {
    isBoothMode,
    isDevMode,
    isKioskMode,
  };
}

export function goToAdminMode() {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.delete('mode');
  url.searchParams.delete('booth');
  url.searchParams.delete('dev');
  url.searchParams.delete('boothDev');
  url.searchParams.delete('kiosk');
  url.searchParams.delete('fullscreen');
  url.hash = '';

  window.location.href = url.toString();
}

export function goToBoothMode(input: {
  dev?: boolean;
  kiosk?: boolean;
} = {}) {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.set('mode', 'booth');

  if (input.dev) {
    url.searchParams.set('dev', '1');
  } else {
    url.searchParams.delete('dev');
    url.searchParams.delete('boothDev');
  }

  if (input.kiosk) {
    url.searchParams.set('kiosk', '1');
  } else {
    url.searchParams.delete('kiosk');
    url.searchParams.delete('fullscreen');
  }

  url.hash = '';
  window.location.href = url.toString();
}

export function buildBoothModeHref(input: {
  dev?: boolean;
  kiosk?: boolean;
} = {}) {
  if (typeof window === 'undefined') {
    return '?mode=booth';
  }

  const url = new URL(window.location.href);
  url.searchParams.set('mode', 'booth');

  if (input.dev) {
    url.searchParams.set('dev', '1');
  } else {
    url.searchParams.delete('dev');
    url.searchParams.delete('boothDev');
  }

  if (input.kiosk) {
    url.searchParams.set('kiosk', '1');
  } else {
    url.searchParams.delete('kiosk');
    url.searchParams.delete('fullscreen');
  }

  url.hash = '';

  return `${url.pathname}${url.search}`;
}
TS

cat > apps/booth-ui/src/booth/BoothCustomerScreen.tsx <<'TSX'
import React from 'react';
import {
  boothFlowStepLabels,
  boothFlowSteps,
  type BoothFlowStep,
} from './booth-flow-types';
import { BoothCameraStep } from './BoothCameraStep';
import { BoothCompleteStep } from './BoothCompleteStep';
import { BoothDeliveryStep } from './BoothDeliveryStep';
import { BoothPaymentStep } from './BoothPaymentStep';
import { BoothReviewStep } from './BoothReviewStep';
import { BoothWelcomeStep } from './BoothWelcomeStep';
import { useBoothFlow } from './BoothFlowProvider';

type BoothCustomerScreenProps = {
  showDevNavigation?: boolean;
  showHeader?: boolean;
};

const stepDescriptions: Record<BoothFlowStep, string> = {
  welcome: 'Customer mulai dari layar sambutan sebelum masuk ke pembayaran.',
  payment: 'Customer menyelesaikan payment gate sebelum camera dibuka.',
  camera: 'Customer melakukan countdown capture sesuai layout aktif.',
  review: 'Customer melihat hasil render final dan bisa retake jika perlu.',
  delivery: 'Customer memilih print / download / QR delivery.',
  complete: 'Session selesai dan booth siap di-reset untuk customer berikutnya.',
};

function renderStep(currentStep: BoothFlowStep) {
  if (currentStep === 'welcome') return <BoothWelcomeStep />;
  if (currentStep === 'payment') return <BoothPaymentStep />;
  if (currentStep === 'camera') return <BoothCameraStep />;
  if (currentStep === 'review') return <BoothReviewStep />;
  if (currentStep === 'delivery') return <BoothDeliveryStep />;
  if (currentStep === 'complete') return <BoothCompleteStep />;

  return <BoothWelcomeStep />;
}

export function BoothCustomerScreen({
  showDevNavigation = false,
  showHeader = true,
}: BoothCustomerScreenProps) {
  const {
    session,
    currentStep,
    currentStepIndex,
    isFirstStep,
    isLastStep,
    startSession,
    setStep,
    canAccessStep,
    goNext,
    goBack,
    completeSession,
    resetSession,
    paymentStatus,
    paymentConfirmed,
  } = useBoothFlow();

  const progressPercent =
    ((currentStepIndex + 1) / boothFlowSteps.length) * 100;

  return (
    <div className="overflow-hidden rounded-[2rem] border border-slate-200 bg-slate-950 text-white shadow-sm">
      <div className="bg-[radial-gradient(circle_at_top_left,rgba(59,130,246,0.35),transparent_35%),radial-gradient(circle_at_bottom_right,rgba(16,185,129,0.25),transparent_35%)] p-6">
        {showHeader && (
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
                Customer Booth Mode
              </p>
              <h3 className="mt-3 text-3xl font-black">
                {boothFlowStepLabels[currentStep]}
              </h3>
              <p className="mt-2 max-w-2xl text-sm font-semibold text-white/70">
                {stepDescriptions[currentStep]}
              </p>
            </div>

            <div className="flex flex-wrap gap-2">
              <span className="rounded-full bg-white px-4 py-2 text-xs font-black text-slate-950">
                {session ? 'Session Active' : 'No Session'}
              </span>

              <span
                className={`rounded-full px-4 py-2 text-xs font-black text-white ${
                  paymentConfirmed ? 'bg-emerald-600' : 'bg-amber-500'
                }`}
              >
                {paymentConfirmed ? 'Payment Confirmed' : 'Payment Locked'}
              </span>
            </div>
          </div>
        )}

        <div className={showHeader ? 'mt-6' : ''}>
          <div className="h-3 overflow-hidden rounded-full bg-white/15">
            <div
              className="h-full rounded-full bg-white"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>

        {showDevNavigation && (
          <div className="mt-4 rounded-3xl border border-white/10 bg-black/20 p-4">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
                  Developer Navigation
                </p>
                <p className="mt-1 text-xs font-bold text-white/50">
                  Only visible in admin preview or booth dev mode.
                </p>
              </div>

              <span className="rounded-full bg-violet-500 px-3 py-1 text-xs font-black text-white">
                DEV MODE
              </span>
            </div>

            <div className="mt-4 grid gap-2 sm:grid-cols-6">
              {boothFlowSteps.map((step, index) => {
                const isActive = step === currentStep;
                const isDone = index < currentStepIndex;
                const isLocked = !canAccessStep(step);

                return (
                  <button
                    key={step}
                    type="button"
                    onClick={() => setStep(step)}
                    className={`rounded-2xl px-3 py-3 text-xs font-black ${
                      isActive
                        ? 'bg-white text-slate-950'
                        : isLocked
                          ? 'bg-red-500/20 text-red-100'
                          : isDone
                            ? 'bg-emerald-400/90 text-slate-950'
                            : 'bg-white/10 text-white/70'
                    }`}
                  >
                    {index + 1}. {boothFlowStepLabels[step]}
                    {isLocked ? ' · Locked' : ''}
                  </button>
                );
              })}
            </div>

            <div className="mt-4 grid gap-3 sm:grid-cols-4">
              <button
                type="button"
                onClick={session ? resetSession : startSession}
                className="rounded-2xl bg-white px-4 py-3 text-xs font-black text-slate-950"
              >
                {session ? 'Reset Session' : 'Start Session'}
              </button>

              <button
                type="button"
                onClick={goBack}
                disabled={isFirstStep}
                className="rounded-2xl border border-white/20 bg-white/10 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
              >
                Back
              </button>

              <button
                type="button"
                onClick={goNext}
                disabled={isLastStep}
                className="rounded-2xl border border-white/20 bg-white/10 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
              >
                Next
              </button>

              <button
                type="button"
                onClick={completeSession}
                className="rounded-2xl bg-emerald-400 px-4 py-3 text-xs font-black text-slate-950"
              >
                Complete
              </button>
            </div>

            <div className="mt-4 rounded-2xl bg-black/20 p-3 font-mono text-[11px] font-bold text-white/60">
              <p>Payment status: {paymentStatus}</p>
              <p>Session ID: {session?.id || 'none'}</p>
            </div>
          </div>
        )}

        {!showDevNavigation && (
          <div className="mt-4 rounded-3xl border border-white/10 bg-black/20 p-4">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
                  Booth Progress
                </p>
                <p className="mt-1 text-sm font-bold text-white/70">
                  Step {currentStepIndex + 1} of {boothFlowSteps.length} ·{' '}
                  {boothFlowStepLabels[currentStep]}
                </p>
              </div>

              <span
                className={`rounded-full px-3 py-1 text-xs font-black text-white ${
                  paymentConfirmed ? 'bg-emerald-600' : 'bg-amber-500'
                }`}
              >
                {paymentConfirmed ? 'Camera Unlocked' : 'Camera Locked'}
              </span>
            </div>
          </div>
        )}

        <div className="mt-6 rounded-3xl bg-white/10 p-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/50">
            Current Customer Screen
          </p>

          {renderStep(currentStep)}
        </div>
      </div>
    </div>
  );
}
TSX

cat > apps/booth-ui/src/booth/BoothModePage.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/booth/BoothFlowPreviewPanel.tsx <<'TSX'
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
TSX

INDEX="apps/booth-ui/src/booth/index.ts"
grep -q "booth-mode-utils" "$INDEX" || cat >> "$INDEX" <<'TS'
export * from './booth-mode-utils';
TS

echo ""
echo "Relevant lines:"
grep -R "showDevNavigation\\|Production Mode\\|Open Production Booth\\|booth-mode-utils\\|Developer Navigation" -n apps/booth-ui/src/booth || true

echo ""
echo "9B10 done."
