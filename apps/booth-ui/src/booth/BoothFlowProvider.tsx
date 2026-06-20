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
