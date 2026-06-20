#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B1 - Customer Booth Flow Foundation"
echo "========================================"

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/booth-flow-types.ts <<'TS'
export type BoothFlowStep =
  | 'welcome'
  | 'payment'
  | 'camera'
  | 'review'
  | 'delivery'
  | 'complete';

export type BoothCustomerSession = {
  id: string;
  startedAt: string;
  completedAt?: string;
  currentStep: BoothFlowStep;
};

export const boothFlowSteps: BoothFlowStep[] = [
  'welcome',
  'payment',
  'camera',
  'review',
  'delivery',
  'complete',
];

export const boothFlowStepLabels: Record<BoothFlowStep, string> = {
  welcome: 'Welcome',
  payment: 'Payment',
  camera: 'Camera',
  review: 'Review',
  delivery: 'Delivery',
  complete: 'Complete',
};
TS

cat > apps/booth-ui/src/booth/BoothFlowProvider.tsx <<'TSX'
import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  boothFlowSteps,
  type BoothCustomerSession,
  type BoothFlowStep,
} from './booth-flow-types';

type BoothFlowContextValue = {
  session: BoothCustomerSession | null;
  currentStep: BoothFlowStep;
  currentStepIndex: number;
  isFirstStep: boolean;
  isLastStep: boolean;
  startSession: () => BoothCustomerSession;
  setStep: (step: BoothFlowStep) => void;
  goNext: () => void;
  goBack: () => void;
  completeSession: () => void;
  resetSession: () => void;
};

const BoothFlowContext = createContext<BoothFlowContextValue | null>(null);

type BoothFlowProviderProps = {
  children: ReactNode;
};

function createSession(): BoothCustomerSession {
  return {
    id: `booth-session-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    startedAt: new Date().toISOString(),
    currentStep: 'welcome',
  };
}

export function BoothFlowProvider({ children }: BoothFlowProviderProps) {
  const [session, setSession] = useState<BoothCustomerSession | null>(null);
  const currentStep = session?.currentStep || 'welcome';
  const currentStepIndex = boothFlowSteps.indexOf(currentStep);

  const startSession = useCallback(() => {
    const nextSession = createSession();
    setSession(nextSession);
    return nextSession;
  }, []);

  const setStep = useCallback((step: BoothFlowStep) => {
    setSession((current) => {
      const safeSession = current || createSession();

      return {
        ...safeSession,
        currentStep: step,
      };
    });
  }, []);

  const goNext = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();
      const index = boothFlowSteps.indexOf(safeSession.currentStep);
      const nextStep =
        boothFlowSteps[Math.min(boothFlowSteps.length - 1, index + 1)];

      return {
        ...safeSession,
        currentStep: nextStep,
        completedAt:
          nextStep === 'complete'
            ? new Date().toISOString()
            : safeSession.completedAt,
      };
    });
  }, []);

  const goBack = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();
      const index = boothFlowSteps.indexOf(safeSession.currentStep);
      const previousStep = boothFlowSteps[Math.max(0, index - 1)];

      return {
        ...safeSession,
        currentStep: previousStep,
      };
    });
  }, []);

  const completeSession = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();

      return {
        ...safeSession,
        currentStep: 'complete',
        completedAt: new Date().toISOString(),
      };
    });
  }, []);

  const resetSession = useCallback(() => {
    setSession(null);
  }, []);

  const value = useMemo<BoothFlowContextValue>(() => {
    return {
      session,
      currentStep,
      currentStepIndex,
      isFirstStep: currentStepIndex <= 0,
      isLastStep: currentStepIndex >= boothFlowSteps.length - 1,
      startSession,
      setStep,
      goNext,
      goBack,
      completeSession,
      resetSession,
    };
  }, [
    session,
    currentStep,
    currentStepIndex,
    startSession,
    setStep,
    goNext,
    goBack,
    completeSession,
    resetSession,
  ]);

  return (
    <BoothFlowContext.Provider value={value}>
      {children}
    </BoothFlowContext.Provider>
  );
}

export function useBoothFlow(): BoothFlowContextValue {
  const context = useContext(BoothFlowContext);

  if (!context) {
    throw new Error('useBoothFlow must be used inside BoothFlowProvider');
  }

  return context;
}
TSX

cat > apps/booth-ui/src/booth/BoothCustomerScreen.tsx <<'TSX'
import React from 'react';
import {
  boothFlowStepLabels,
  boothFlowSteps,
  type BoothFlowStep,
} from './booth-flow-types';
import { useBoothFlow } from './BoothFlowProvider';

const stepDescriptions: Record<BoothFlowStep, string> = {
  welcome: 'Customer mulai dari layar sambutan sebelum masuk ke pembayaran.',
  payment: 'Customer menyelesaikan payment gate sebelum camera dibuka.',
  camera: 'Customer melakukan countdown capture sesuai layout aktif.',
  review: 'Customer melihat hasil render final dan bisa retake jika perlu.',
  delivery: 'Customer memilih print / download / QR delivery.',
  complete: 'Session selesai dan booth siap di-reset untuk customer berikutnya.',
};

export function BoothCustomerScreen() {
  const {
    session,
    currentStep,
    currentStepIndex,
    isFirstStep,
    isLastStep,
    startSession,
    setStep,
    goNext,
    goBack,
    completeSession,
    resetSession,
  } = useBoothFlow();

  const progressPercent =
    ((currentStepIndex + 1) / boothFlowSteps.length) * 100;

  return (
    <div className="overflow-hidden rounded-[2rem] border border-slate-200 bg-slate-950 text-white shadow-sm">
      <div className="bg-[radial-gradient(circle_at_top_left,rgba(59,130,246,0.35),transparent_35%),radial-gradient(circle_at_bottom_right,rgba(16,185,129,0.25),transparent_35%)] p-6">
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

          <span className="rounded-full bg-white px-4 py-2 text-xs font-black text-slate-950">
            {session ? 'Session Active' : 'No Session'}
          </span>
        </div>

        <div className="mt-6 h-3 overflow-hidden rounded-full bg-white/15">
          <div
            className="h-full rounded-full bg-white"
            style={{ width: `${progressPercent}%` }}
          />
        </div>

        <div className="mt-4 grid gap-2 sm:grid-cols-6">
          {boothFlowSteps.map((step, index) => {
            const isActive = step === currentStep;
            const isDone = index < currentStepIndex;

            return (
              <button
                key={step}
                type="button"
                onClick={() => setStep(step)}
                className={`rounded-2xl px-3 py-3 text-xs font-black ${
                  isActive
                    ? 'bg-white text-slate-950'
                    : isDone
                      ? 'bg-emerald-400/90 text-slate-950'
                      : 'bg-white/10 text-white/70'
                }`}
              >
                {index + 1}. {boothFlowStepLabels[step]}
              </button>
            );
          })}
        </div>

        <div className="mt-6 rounded-3xl bg-white/10 p-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/50">
            Current Customer Screen
          </p>

          {currentStep === 'welcome' && (
            <div className="mt-4">
              <h4 className="text-4xl font-black">Welcome to Corra Booth</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Tap start untuk mulai sesi photobooth.
              </p>
            </div>
          )}

          {currentStep === 'payment' && (
            <div className="mt-4">
              <h4 className="text-4xl font-black">Complete Payment</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Payment gate nanti disambungkan ke PaymentTransactionProvider.
              </p>
            </div>
          )}

          {currentStep === 'camera' && (
            <div className="mt-4">
              <h4 className="text-4xl font-black">Get Ready</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Camera full-screen customer capture akan ditempel di phase berikutnya.
              </p>
            </div>
          )}

          {currentStep === 'review' && (
            <div className="mt-4">
              <h4 className="text-4xl font-black">Review Your Photo</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Hasil final render akan tampil di sini.
              </p>
            </div>
          )}

          {currentStep === 'delivery' && (
            <div className="mt-4">
              <h4 className="text-4xl font-black">Print or Download</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Customer bisa pilih print atau delivery QR.
              </p>
            </div>
          )}

          {currentStep === 'complete' && (
            <div className="mt-4">
              <h4 className="text-4xl font-black">Thank You!</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Session selesai. Booth siap reset ke welcome screen.
              </p>
            </div>
          )}
        </div>

        <div className="mt-6 grid gap-3 sm:grid-cols-4">
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

        {session && (
          <div className="mt-4 rounded-2xl bg-black/20 p-3 font-mono text-[11px] font-bold text-white/60">
            Session ID: {session.id}
          </div>
        )}
      </div>
    </div>
  );
}
TSX

cat > apps/booth-ui/src/booth/BoothFlowPreviewPanel.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/booth/index.ts <<'TS'
export * from './booth-flow-types';
export * from './BoothFlowProvider';
export * from './BoothCustomerScreen';
export * from './BoothFlowPreviewPanel';
TS

SETUP="apps/booth-ui/src/camera/CameraSetupPanel.tsx"

[ -f "$SETUP" ] || {
  echo "ERROR: $SETUP not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraSetupPanel.tsx")
text = path.read_text()

if "BoothFlowPreviewPanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { BoothFlowPreviewPanel } from '../booth';",
    )

    text = "\n".join(lines) + "\n"

if "<BoothFlowPreviewPanel />" not in text:
    marker = "<CameraCustomerSessionResetPanel />"

    if marker in text:
        text = text.replace(
            marker,
            marker + "\n      <BoothFlowPreviewPanel />",
            1,
        )
    else:
        text = text.replace(
            "    </",
            "      <BoothFlowPreviewPanel />\n    </",
            1,
        )

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "BoothFlowPreviewPanel\\|Customer Booth Mode\\|BoothFlowProvider" -n apps/booth-ui/src/booth apps/booth-ui/src/camera/CameraSetupPanel.tsx || true

echo ""
echo "9B1 done."
