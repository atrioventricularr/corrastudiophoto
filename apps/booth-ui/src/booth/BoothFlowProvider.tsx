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
