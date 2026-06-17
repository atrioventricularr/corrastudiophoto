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
import {
  isSessionLifecycleSyncConfigured,
  recordBoothSessionLifecycle,
} from './supabase-session-lifecycle-sync';
import type {
  CorraBoothSession,
  CorraSessionLifecycleEvent,
  CorraSessionStatus,
  SessionLifecycleContextValue,
  SessionLifecycleSyncStatus,
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
  const [syncStatus, setSyncStatus] =
    useState<SessionLifecycleSyncStatus>('idle');
  const [lastSyncedAt, setLastSyncedAt] = useState<string | null>(null);
  const [syncError, setSyncError] = useState<string | null>(null);

  useEffect(() => {
    saveCurrentSession(currentSession);
  }, [currentSession]);

  useEffect(() => {
    saveSessionHistory(sessionHistory);
  }, [sessionHistory]);

  useEffect(() => {
    saveLifecycleEvents(lifecycleEvents);
  }, [lifecycleEvents]);

  useEffect(() => {
    if (!currentSession) {
      return;
    }

    if (!isSessionLifecycleSyncConfigured()) {
      return;
    }

    const currentSessionEvents = lifecycleEvents.filter(
      (event) => event.sessionId === currentSession.id,
    );

    const timer = window.setTimeout(() => {
      void recordBoothSessionLifecycle({
        session: currentSession,
        events: currentSessionEvents,
      }).then((result) => {
        if (!result.ok) {
          console.warn(
            '[Corra] Failed to sync session lifecycle:',
            result.error,
          );
        }
      });
    }, 700);

    return () => {
      window.clearTimeout(timer);
    };
  }, [currentSession, lifecycleEvents]);

  const appendEvent = useCallback((event: CorraSessionLifecycleEvent) => {
    setLifecycleEvents((current) => [event, ...current].slice(0, 300));
  }, []);

  const upsertSessionHistory = useCallback((session: CorraBoothSession) => {
    setSessionHistory((current) => {
      const withoutCurrent = current.filter((item) => item.id !== session.id);
      return sortSessions([session, ...withoutCurrent]).slice(0, 100);
    });
  }, []);

  const syncCurrentSession = useCallback(async () => {
    if (!currentSession) {
      setSyncStatus('skipped');
      setSyncError('No active session to sync.');
      return;
    }

    if (!isSessionLifecycleSyncConfigured()) {
      setSyncStatus('skipped');
      setSyncError(
        'Session lifecycle sync is not configured. Check .env.local.',
      );
      return;
    }

    const currentSessionEvents = lifecycleEvents.filter(
      (event) => event.sessionId === currentSession.id,
    );

    setSyncStatus('syncing');
    setSyncError(null);

    const result = await recordBoothSessionLifecycle({
      session: currentSession,
      events: currentSessionEvents,
    });

    if (!result.ok) {
      setSyncStatus('failed');
      setSyncError(result.error || 'Failed to sync session lifecycle.');
      console.warn(
        '[Corra] Failed to sync session lifecycle:',
        result.error,
      );
      return;
    }

    setSyncStatus('synced');
    setLastSyncedAt(result.syncedAt || new Date().toISOString());
    setSyncError(null);
  }, [currentSession, lifecycleEvents]);

  useEffect(() => {
    if (!currentSession) {
      return;
    }

    const timer = window.setTimeout(() => {
      void syncCurrentSession();
    }, 900);

    return () => {
      window.clearTimeout(timer);
    };
  }, [currentSession, lifecycleEvents, syncCurrentSession]);

  // session_lifecycle_manual_sync

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
      syncStatus,
      lastSyncedAt,
      syncError,
      syncCurrentSession,
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
