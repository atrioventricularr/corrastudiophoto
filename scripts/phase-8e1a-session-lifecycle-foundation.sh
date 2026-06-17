#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E1A - Session Lifecycle Foundation"
echo "========================================"

mkdir -p apps/booth-ui/src/sessions

cat > apps/booth-ui/src/sessions/types.ts <<'TS'
export type CorraSessionStatus =
  | 'idle'
  | 'session_created'
  | 'payment_pending'
  | 'payment_confirmed'
  | 'layout_selected'
  | 'template_selected'
  | 'capturing'
  | 'captured'
  | 'processing'
  | 'completed'
  | 'delivered'
  | 'cancelled'
  | 'failed';

export type CorraSessionLifecycleEvent = {
  id: string;
  sessionId: string;
  fromStatus: CorraSessionStatus | null;
  toStatus: CorraSessionStatus;
  reason?: string | null;
  metadata?: Record<string, unknown>;
  createdAt: string;
};

export type CorraBoothSession = {
  id: string;
  status: CorraSessionStatus;
  paymentTransactionId?: string | null;
  paymentConfirmationCode?: string | null;
  voucherCode?: string | null;
  layoutId?: string | null;
  templateId?: string | null;
  captureCount?: number;
  finalAssetUrl?: string | null;
  gifAssetUrl?: string | null;
  errorMessage?: string | null;
  metadata?: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
  completedAt?: string | null;
  cancelledAt?: string | null;
};

export type StartBoothSessionInput = {
  metadata?: Record<string, unknown>;
};

export type TransitionBoothSessionInput = {
  toStatus: CorraSessionStatus;
  reason?: string | null;
  metadata?: Record<string, unknown>;
  patch?: Partial<CorraBoothSession>;
};

export type SessionLifecycleContextValue = {
  currentSession: CorraBoothSession | null;
  sessionHistory: CorraBoothSession[];
  lifecycleEvents: CorraSessionLifecycleEvent[];
  startBoothSession: (input?: StartBoothSessionInput) => CorraBoothSession;
  transitionBoothSession: (
    input: TransitionBoothSessionInput,
  ) => CorraBoothSession | null;
  cancelBoothSession: (reason?: string) => CorraBoothSession | null;
  failBoothSession: (reason?: string) => CorraBoothSession | null;
  clearSessionHistory: () => void;
};
TS

cat > apps/booth-ui/src/sessions/local-session-storage.ts <<'TS'
import type {
  CorraBoothSession,
  CorraSessionLifecycleEvent,
} from './types';

const SESSION_HISTORY_KEY = 'corra.sessionHistory.v1';
const SESSION_EVENTS_KEY = 'corra.sessionLifecycleEvents.v1';
const CURRENT_SESSION_KEY = 'corra.currentSession.v1';

export function loadCurrentSession(): CorraBoothSession | null {
  if (typeof window === 'undefined') return null;

  try {
    const raw = window.localStorage.getItem(CURRENT_SESSION_KEY);
    return raw ? (JSON.parse(raw) as CorraBoothSession) : null;
  } catch {
    return null;
  }
}

export function saveCurrentSession(session: CorraBoothSession | null): void {
  if (typeof window === 'undefined') return;

  if (!session) {
    window.localStorage.removeItem(CURRENT_SESSION_KEY);
    return;
  }

  window.localStorage.setItem(CURRENT_SESSION_KEY, JSON.stringify(session));
}

export function loadSessionHistory(): CorraBoothSession[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(SESSION_HISTORY_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveSessionHistory(sessions: CorraBoothSession[]): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(
    SESSION_HISTORY_KEY,
    JSON.stringify(sessions.slice(0, 100)),
  );
}

export function loadLifecycleEvents(): CorraSessionLifecycleEvent[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(SESSION_EVENTS_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveLifecycleEvents(events: CorraSessionLifecycleEvent[]): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(
    SESSION_EVENTS_KEY,
    JSON.stringify(events.slice(0, 300)),
  );
}

export function clearLocalSessionLifecycle(): void {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(CURRENT_SESSION_KEY);
  window.localStorage.removeItem(SESSION_HISTORY_KEY);
  window.localStorage.removeItem(SESSION_EVENTS_KEY);
}
TS

cat > apps/booth-ui/src/sessions/SessionLifecycleProvider.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/sessions/index.ts <<'TS'
export * from './types';
export * from './local-session-storage';
export * from './SessionLifecycleProvider';
TS

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/main.tsx")
text = path.read_text()

if "SessionLifecycleProvider" not in text:
    text = text.replace(
        "import { PaymentSettingsProvider, PaymentTransactionProvider } from './payments';",
        "import { PaymentSettingsProvider, PaymentTransactionProvider } from './payments';\nimport { SessionLifecycleProvider } from './sessions';"
    )

if "<SessionLifecycleProvider>" not in text:
    text = text.replace(
        """<PaymentTransactionProvider>
          <ThemedBackground />
          <App />
        </PaymentTransactionProvider>""",
        """<PaymentTransactionProvider>
          <SessionLifecycleProvider>
            <ThemedBackground />
            <App />
          </SessionLifecycleProvider>
        </PaymentTransactionProvider>"""
    )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/main.tsx")
PY

echo ""
echo "Created:"
echo "- apps/booth-ui/src/sessions/types.ts"
echo "- apps/booth-ui/src/sessions/local-session-storage.ts"
echo "- apps/booth-ui/src/sessions/SessionLifecycleProvider.tsx"
echo "- apps/booth-ui/src/sessions/index.ts"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/main.tsx"
echo ""
echo "Phase 8E1A completed."
