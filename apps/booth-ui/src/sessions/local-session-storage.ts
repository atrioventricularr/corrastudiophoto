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
