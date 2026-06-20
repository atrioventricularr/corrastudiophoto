import type {
  BoothLifecycleEvent,
  BoothLifecycleEventType,
} from './booth-lifecycle-types';
import type {
  BoothFlowStep,
  BoothPaymentStatus,
} from './booth-flow-types';

const BOOTH_LIFECYCLE_EVENTS_KEY = 'corra.booth.lifecycle.events.v1';
const MAX_EVENTS = 250;

function createEventId() {
  if (
    typeof window !== 'undefined' &&
    window.crypto &&
    typeof window.crypto.randomUUID === 'function'
  ) {
    return window.crypto.randomUUID();
  }

  return `booth-event-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function loadBoothLifecycleEvents(): BoothLifecycleEvent[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(BOOTH_LIFECYCLE_EVENTS_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed.filter((event) => {
      return (
        event &&
        typeof event.id === 'string' &&
        typeof event.type === 'string' &&
        typeof event.at === 'string' &&
        typeof event.summary === 'string'
      );
    });
  } catch (error) {
    console.warn('[Corra Booth] Failed to load lifecycle events:', error);
    return [];
  }
}

export function saveBoothLifecycleEvents(events: BoothLifecycleEvent[]) {
  if (typeof window === 'undefined') return;

  try {
    const limitedEvents = events.slice(-MAX_EVENTS);
    window.localStorage.setItem(
      BOOTH_LIFECYCLE_EVENTS_KEY,
      JSON.stringify(limitedEvents),
    );
  } catch (error) {
    console.warn('[Corra Booth] Failed to save lifecycle events:', error);
  }
}

export function clearStoredBoothLifecycleEvents() {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(BOOTH_LIFECYCLE_EVENTS_KEY);
}

export function createBoothLifecycleEvent(input: {
  type: BoothLifecycleEventType;
  summary: string;
  sessionId?: string;
  step?: BoothFlowStep;
  paymentStatus?: BoothPaymentStatus;
  payload?: Record<string, unknown>;
}): BoothLifecycleEvent {
  return {
    id: createEventId(),
    type: input.type,
    at: new Date().toISOString(),
    sessionId: input.sessionId,
    step: input.step,
    paymentStatus: input.paymentStatus,
    summary: input.summary,
    payload: input.payload,
  };
}

export function appendStoredBoothLifecycleEvent(
  event: BoothLifecycleEvent,
): BoothLifecycleEvent[] {
  const events = [...loadBoothLifecycleEvents(), event].slice(-MAX_EVENTS);
  saveBoothLifecycleEvents(events);
  return events;
}
