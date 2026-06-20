#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B5 - Payment Confirmed Gate"
echo "========================================"

TYPES="apps/booth-ui/src/booth/booth-flow-types.ts"
PROVIDER="apps/booth-ui/src/booth/BoothFlowProvider.tsx"
PAYMENT="apps/booth-ui/src/booth/BoothPaymentStep.tsx"
SCREEN="apps/booth-ui/src/booth/BoothCustomerScreen.tsx"

[ -f "$TYPES" ] || {
  echo "ERROR: $TYPES not found. Run 9B1 first."
  exit 1
}

[ -f "$PROVIDER" ] || {
  echo "ERROR: $PROVIDER not found. Run 9B1 first."
  exit 1
}

[ -f "$PAYMENT" ] || {
  echo "ERROR: $PAYMENT not found. Run 9B4 first."
  exit 1
}

cat > "$TYPES" <<'TS'
export type BoothFlowStep =
  | 'welcome'
  | 'payment'
  | 'camera'
  | 'review'
  | 'delivery'
  | 'complete';

export type BoothPaymentStatus =
  | 'idle'
  | 'pending'
  | 'confirmed'
  | 'failed';

export type BoothCustomerSession = {
  id: string;
  startedAt: string;
  completedAt?: string;
  currentStep: BoothFlowStep;
  paymentStatus: BoothPaymentStatus;
  paymentConfirmedAt?: string;
};

export const boothFlowSteps: BoothFlowStep[] = [
  'welcome',
  'payment',
  'camera',
  'review',
  'delivery',
  'complete',
];

export const boothProtectedSteps: BoothFlowStep[] = [
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

cat > "$PROVIDER" <<'TSX'
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
  boothProtectedSteps,
  type BoothCustomerSession,
  type BoothFlowStep,
  type BoothPaymentStatus,
} from './booth-flow-types';

type BoothFlowContextValue = {
  session: BoothCustomerSession | null;
  currentStep: BoothFlowStep;
  currentStepIndex: number;
  paymentStatus: BoothPaymentStatus;
  paymentConfirmed: boolean;
  isFirstStep: boolean;
  isLastStep: boolean;
  startSession: () => BoothCustomerSession;
  setStep: (step: BoothFlowStep) => void;
  canAccessStep: (step: BoothFlowStep) => boolean;
  goNext: () => void;
  goBack: () => void;
  markPaymentPending: () => void;
  markPaymentConfirmed: () => void;
  markPaymentFailed: () => void;
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
    paymentStatus: 'idle',
  };
}

function isProtectedStep(step: BoothFlowStep) {
  return boothProtectedSteps.includes(step);
}

function resolveAllowedStep(
  step: BoothFlowStep,
  paymentStatus: BoothPaymentStatus,
): BoothFlowStep {
  if (isProtectedStep(step) && paymentStatus !== 'confirmed') {
    return 'payment';
  }

  return step;
}

export function BoothFlowProvider({ children }: BoothFlowProviderProps) {
  const [session, setSession] = useState<BoothCustomerSession | null>(null);
  const currentStep = session?.currentStep || 'welcome';
  const paymentStatus = session?.paymentStatus || 'idle';
  const paymentConfirmed = paymentStatus === 'confirmed';
  const currentStepIndex = boothFlowSteps.indexOf(currentStep);

  const startSession = useCallback(() => {
    const nextSession = createSession();
    setSession(nextSession);
    return nextSession;
  }, []);

  const canAccessStep = useCallback(
    (step: BoothFlowStep) => {
      return !isProtectedStep(step) || paymentStatus === 'confirmed';
    },
    [paymentStatus],
  );

  const setStep = useCallback((step: BoothFlowStep) => {
    setSession((current) => {
      const safeSession = current || createSession();
      const allowedStep = resolveAllowedStep(step, safeSession.paymentStatus);

      return {
        ...safeSession,
        currentStep: allowedStep,
      };
    });
  }, []);

  const goNext = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();
      const index = boothFlowSteps.indexOf(safeSession.currentStep);
      const requestedStep =
        boothFlowSteps[Math.min(boothFlowSteps.length - 1, index + 1)];
      const nextStep = resolveAllowedStep(
        requestedStep,
        safeSession.paymentStatus,
      );

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

  const markPaymentPending = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();

      return {
        ...safeSession,
        paymentStatus: 'pending',
        currentStep: 'payment',
      };
    });
  }, []);

  const markPaymentConfirmed = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();

      return {
        ...safeSession,
        paymentStatus: 'confirmed',
        paymentConfirmedAt: new Date().toISOString(),
        currentStep: 'camera',
      };
    });
  }, []);

  const markPaymentFailed = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();

      return {
        ...safeSession,
        paymentStatus: 'failed',
        currentStep: 'payment',
      };
    });
  }, []);

  const completeSession = useCallback(() => {
    setSession((current) => {
      const safeSession = current || createSession();
      const nextStep = resolveAllowedStep('complete', safeSession.paymentStatus);

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

  const resetSession = useCallback(() => {
    setSession(null);
  }, []);

  const value = useMemo<BoothFlowContextValue>(() => {
    return {
      session,
      currentStep,
      currentStepIndex,
      paymentStatus,
      paymentConfirmed,
      isFirstStep: currentStepIndex <= 0,
      isLastStep: currentStepIndex >= boothFlowSteps.length - 1,
      startSession,
      setStep,
      canAccessStep,
      goNext,
      goBack,
      markPaymentPending,
      markPaymentConfirmed,
      markPaymentFailed,
      completeSession,
      resetSession,
    };
  }, [
    session,
    currentStep,
    currentStepIndex,
    paymentStatus,
    paymentConfirmed,
    startSession,
    setStep,
    canAccessStep,
    goNext,
    goBack,
    markPaymentPending,
    markPaymentConfirmed,
    markPaymentFailed,
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

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/BoothPaymentStep.tsx")
text = path.read_text()

text = text.replace(
    "  const { setStep } = useBoothFlow();",
    "  const {\n    paymentStatus,\n    markPaymentPending,\n    markPaymentConfirmed,\n    markPaymentFailed,\n    setStep,\n  } = useBoothFlow();",
    1,
)

text = text.replace(
    """  const handleConfirmPayment = () => {
    setStep('camera');
  };""",
    """  const handleConfirmPayment = () => {
    markPaymentConfirmed();
  };

  const handleSetPending = () => {
    markPaymentPending();
  };

  const handleSetFailed = () => {
    markPaymentFailed();
  };""",
    1,
)

if "Payment Status" not in text:
    marker = """          <div className="rounded-3xl bg-emerald-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
              Active Provider
            </p>
            <p className="mt-2 text-lg font-black text-emerald-800">
              {provider}
            </p>
          </div>"""

    replacement = marker + """

          <div className="rounded-3xl bg-violet-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-violet-500">
              Payment Status
            </p>
            <p className="mt-2 text-lg font-black uppercase text-violet-800">
              {paymentStatus}
            </p>
          </div>"""

    if marker not in text:
        raise SystemExit("Could not find provider card marker in BoothPaymentStep.")

    text = text.replace(marker, replacement, 1)

if "Mark Pending" not in text:
    text = text.replace(
        """        <div className="mt-6 grid gap-3 sm:grid-cols-2">
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
        </div>""",
        """        <div className="mt-6 grid gap-3 sm:grid-cols-2">
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
        </div>""",
        1,
    )

path.write_text(text)
print("PATCH:", path)
PY

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/BoothCustomerScreen.tsx")
text = path.read_text()

text = text.replace(
    "    setStep,",
    "    setStep,\n    canAccessStep,\n    paymentStatus,\n    paymentConfirmed,",
    1,
)

if "Locked" not in text:
    text = text.replace(
        """          {boothFlowSteps.map((step, index) => {
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
          })}""",
        """          {boothFlowSteps.map((step, index) => {
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
          })}""",
        1,
    )

if "Payment Gate" not in text:
    marker = """        <div className="mt-6 rounded-3xl bg-white/10 p-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/50">
            Current Customer Screen
          </p>"""

    replacement = """        <div className="mt-4 rounded-3xl border border-white/10 bg-black/20 p-4">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
                Payment Gate
              </p>
              <p className="mt-1 text-sm font-bold text-white/70">
                Status: <span className="uppercase">{paymentStatus}</span>
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

        <div className="mt-6 rounded-3xl bg-white/10 p-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/50">
            Current Customer Screen
          </p>"""

    if marker not in text:
        raise SystemExit("Could not find Current Customer Screen marker.")

    text = text.replace(marker, replacement, 1)

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "paymentStatus\\|paymentConfirmed\\|markPaymentConfirmed\\|Camera Locked\\|Locked" -n apps/booth-ui/src/booth || true

echo ""
echo "9B5 done."
