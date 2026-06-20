import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  appendStoredBoothLifecycleEvent,
  clearStoredBoothLifecycleEvents,
  createBoothLifecycleEvent,
  loadBoothLifecycleEvents,
  saveBoothLifecycleEvents,
} from './booth-lifecycle-storage';
import type {
  BoothLifecycleEvent,
  BoothLifecycleEventType,
} from './booth-lifecycle-types';
import type {
  BoothFlowStep,
  BoothPaymentStatus,
} from './booth-flow-types';

type RecordBoothEventInput = {
  type: BoothLifecycleEventType;
  summary: string;
  sessionId?: string;
  step?: BoothFlowStep;
  paymentStatus?: BoothPaymentStatus;
  payload?: Record<string, unknown>;
};

type BoothLifecycleLoggerContextValue = {
  events: BoothLifecycleEvent[];
  latestEvent: BoothLifecycleEvent | null;
  recordBoothEvent: (input: RecordBoothEventInput) => BoothLifecycleEvent;
  clearBoothEvents: () => void;
  replaceBoothEvents: (events: BoothLifecycleEvent[]) => void;
};

const BoothLifecycleLoggerContext =
  createContext<BoothLifecycleLoggerContextValue | null>(null);

type BoothLifecycleLoggerProviderProps = {
  children: ReactNode;
};

export function BoothLifecycleLoggerProvider({
  children,
}: BoothLifecycleLoggerProviderProps) {
  const [events, setEvents] = useState<BoothLifecycleEvent[]>(() =>
    loadBoothLifecycleEvents(),
  );

  const recordBoothEvent = useCallback((input: RecordBoothEventInput) => {
    const event = createBoothLifecycleEvent(input);
    const nextEvents = appendStoredBoothLifecycleEvent(event);
    setEvents(nextEvents);
    return event;
  }, []);

  const clearBoothEvents = useCallback(() => {
    clearStoredBoothLifecycleEvents();
    setEvents([]);
  }, []);

  const replaceBoothEvents = useCallback((nextEvents: BoothLifecycleEvent[]) => {
    saveBoothLifecycleEvents(nextEvents);
    setEvents(nextEvents);
  }, []);

  const value = useMemo<BoothLifecycleLoggerContextValue>(() => {
    return {
      events,
      latestEvent: events.at(-1) || null,
      recordBoothEvent,
      clearBoothEvents,
      replaceBoothEvents,
    };
  }, [
    events,
    recordBoothEvent,
    clearBoothEvents,
    replaceBoothEvents,
  ]);

  return (
    <BoothLifecycleLoggerContext.Provider value={value}>
      {children}
    </BoothLifecycleLoggerContext.Provider>
  );
}

export function useBoothLifecycleLogger() {
  const context = useContext(BoothLifecycleLoggerContext);

  if (!context) {
    throw new Error(
      'useBoothLifecycleLogger must be used inside BoothLifecycleLoggerProvider',
    );
  }

  return context;
}
