import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  clearLocalSessionLifecycle,
  loadCurrentSession,
  loadLifecycleEvents,
  loadSessionHistory,
  saveCurrentSession,
  saveLifecycleEvents,
  saveSessionHistory,
} from './local-session-storage';
import type {
  CorraBoothSession,
  CorraSessionLifecycleEvent,
  CorraSessionStatus,
  SessionLifecycleContextValue,
  StartBoothSessionInput,
  TransitionBoothSessionInput,
} from './types';

const SessionLifecycleContext =
  createContext<SessionLifecycleContextValue | null>(null);

type SessionLifecycleProviderProps = {
  children: ReactNode;
};

function createId(prefix: string): string {
  const random =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(16).slice(2)}`;

  return `${prefix}-${random}`;
}

function sortSessions(sessions: CorraBoothSession[]): CorraBoothSession[] {
  return [...sessions].sort((a, b) => {
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });
}

function createLifecycleEvent(input: {
  sessionId: string;
  fromStatus: CorraSessionStatus | null;
  toStatus: CorraSessionStatus;
  reason?: string | null;
  metadata?: Record<string, unknown>;
}): CorraSessionLifecycleEvent {
  return {
    id: createId('event'),
    sessionId: input.sessionId,
    fromStatus: input.fromStatus,
    toStatus: input.toStatus,
    reason: input.reason || null,
    metadata: input.metadata || {},
    createdAt: new Date().toISOString(),
  };
}

export function SessionLifecycleProvider({
  children,
}: SessionLifecycleProviderProps) {
  const [currentSession, setCurrentSession] =
    useState<CorraBoothSession | null>(() => loadCurrentSession());
  const [sessionHistory, setSessionHistory] = useState<CorraBoothSession[]>(
    () => sortSessions(loadSessionHistory()),
  );
  const [lifecycleEvents, setLifecycleEvents] = useState<
    CorraSessionLifecycleEvent[]
  >(() => loadLifecycleEvents());

  useEffect(() => {
    saveCurrentSession(currentSession);
  }, [currentSession]);

  useEffect(() => {
    saveSessionHistory(sessionHistory);
  }, [sessionHistory]);

  useEffect(() => {
    saveLifecycleEvents(lifecycleEvents);
  }, [lifecycleEvents]);

  const appendEvent = useCallback((event: CorraSessionLifecycleEvent) => {
    setLifecycleEvents((current) => [event, ...current].slice(0, 300));
  }, []);

  const upsertSessionHistory = useCallback((session: CorraBoothSession) => {
    setSessionHistory((current) => {
      const withoutCurrent = current.filter((item) => item.id !== session.id);
      return sortSessions([session, ...withoutCurrent]).slice(0, 100);
    });
  }, []);

  const startBoothSession = useCallback(
    (input: StartBoothSessionInput = {}) => {
      const now = new Date().toISOString();

      const session: CorraBoothSession = {
        id: createId('session'),
        status: 'session_created',
        paymentTransactionId: null,
        paymentConfirmationCode: null,
        voucherCode: null,
        layoutId: null,
        templateId: null,
        captureCount: 0,
        finalAssetUrl: null,
        gifAssetUrl: null,
        errorMessage: null,
        metadata: input.metadata || {},
        createdAt: now,
        updatedAt: now,
        completedAt: null,
        cancelledAt: null,
      };

      setCurrentSession(session);
      upsertSessionHistory(session);

      appendEvent(
        createLifecycleEvent({
          sessionId: session.id,
          fromStatus: null,
          toStatus: 'session_created',
          reason: 'session_started',
          metadata: input.metadata,
        }),
      );

      return session;
    },
    [appendEvent, upsertSessionHistory],
  );

  const transitionBoothSession = useCallback(
    (input: TransitionBoothSessionInput) => {
      if (!currentSession) {
        return null;
      }

      const now = new Date().toISOString();

      const nextSession: CorraBoothSession = {
        ...currentSession,
        ...(input.patch || {}),
        status: input.toStatus,
        metadata: {
          ...(currentSession.metadata || {}),
          ...(input.metadata || {}),
        },
        updatedAt: now,
        completedAt:
          input.toStatus === 'completed' || input.toStatus === 'delivered'
            ? now
            : currentSession.completedAt || null,
        cancelledAt:
          input.toStatus === 'cancelled'
            ? now
            : currentSession.cancelledAt || null,
      };

      setCurrentSession(nextSession);
      upsertSessionHistory(nextSession);

      appendEvent(
        createLifecycleEvent({
          sessionId: nextSession.id,
          fromStatus: currentSession.status,
          toStatus: input.toStatus,
          reason: input.reason,
          metadata: input.metadata,
        }),
      );

      return nextSession;
    },
    [appendEvent, currentSession, upsertSessionHistory],
  );

  const cancelBoothSession = useCallback(
    (reason = 'cancelled_by_user') => {
      return transitionBoothSession({
        toStatus: 'cancelled',
        reason,
      });
    },
    [transitionBoothSession],
  );

  const failBoothSession = useCallback(
    (reason = 'session_failed') => {
      return transitionBoothSession({
        toStatus: 'failed',
        reason,
        patch: {
          errorMessage: reason,
        },
      });
    },
    [transitionBoothSession],
  );

  const clearSessionHistory = useCallback(() => {
    clearLocalSessionLifecycle();
    setCurrentSession(null);
    setSessionHistory([]);
    setLifecycleEvents([]);
  }, []);

  const value = useMemo<SessionLifecycleContextValue>(() => {
    return {
      currentSession,
      sessionHistory,
      lifecycleEvents,
      startBoothSession,
      transitionBoothSession,
      cancelBoothSession,
      failBoothSession,
      clearSessionHistory,
    };
  }, [
    currentSession,
    sessionHistory,
    lifecycleEvents,
    startBoothSession,
    transitionBoothSession,
    cancelBoothSession,
    failBoothSession,
    clearSessionHistory,
  ]);

  return (
    <SessionLifecycleContext.Provider value={value}>
      {children}
    </SessionLifecycleContext.Provider>
  );
}

export function useSessionLifecycle(): SessionLifecycleContextValue {
  const context = useContext(SessionLifecycleContext);

  if (!context) {
    throw new Error(
      'useSessionLifecycle must be used inside SessionLifecycleProvider',
    );
  }

  return context;
}
