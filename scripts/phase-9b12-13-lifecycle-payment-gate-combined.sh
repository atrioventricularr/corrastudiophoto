#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo " Phase 9B12-13 - Lifecycle + Payment Gate"
echo "=============================================="

mkdir -p apps/booth-ui/src/booth

PAYMENT_HOOK_FILE="$(
  grep -R "export function usePaymentSettings\|function usePaymentSettings\|export const usePaymentSettings" -l apps/booth-ui/src 2>/dev/null | head -n 1 || true
)"

[ -n "$PAYMENT_HOOK_FILE" ] || {
  echo "ERROR: Could not find usePaymentSettings hook."
  echo "Run:"
  echo "grep -R \"usePaymentSettings\" -n apps/booth-ui/src | head -n 30"
  exit 1
}

PAYMENT_IMPORT="$(
  python - "$PAYMENT_HOOK_FILE" <<'PY'
import os
import sys
from pathlib import Path

target = Path(sys.argv[1]).with_suffix("")
source_dir = Path("apps/booth-ui/src/booth")
rel = os.path.relpath(target, source_dir).replace("\\", "/")

if not rel.startswith("."):
    rel = "./" + rel

print(rel)
PY
)"

echo "Payment hook file: $PAYMENT_HOOK_FILE"
echo "Payment import   : $PAYMENT_IMPORT"

cat > apps/booth-ui/src/booth/booth-lifecycle-types.ts <<'TS'
import type {
  BoothFlowStep,
  BoothPaymentStatus,
} from './booth-flow-types';

export type BoothLifecycleEventType =
  | 'session_started'
  | 'session_reset'
  | 'session_completed'
  | 'step_changed'
  | 'payment_status_changed'
  | 'payment_pending'
  | 'payment_confirmed'
  | 'payment_failed'
  | 'capture_count_changed'
  | 'render_output_created'
  | 'print_job_created'
  | 'print_job_completed'
  | 'print_job_failed'
  | 'download_final_output'
  | 'manual_recovery'
  | 'debug_note';

export type BoothLifecycleEvent = {
  id: string;
  type: BoothLifecycleEventType;
  at: string;
  sessionId?: string;
  step?: BoothFlowStep;
  paymentStatus?: BoothPaymentStatus;
  summary: string;
  payload?: Record<string, unknown>;
};
TS

cat > apps/booth-ui/src/booth/booth-lifecycle-storage.ts <<'TS'
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
TS

cat > apps/booth-ui/src/booth/BoothLifecycleLoggerProvider.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/booth/BoothLifecycleAutoTracker.tsx <<'TSX'
import { useEffect, useMemo, useRef } from 'react';
import {
  useCameraPrintQueue,
  useCameraRenderOutput,
  useCapturedFrames,
} from '../camera';
import { useBoothFlow } from './BoothFlowProvider';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';

export function BoothLifecycleAutoTracker() {
  const {
    session,
    currentStep,
    paymentStatus,
  } = useBoothFlow();

  const {
    capturedFramesBySlotId,
  } = useCapturedFrames();

  const {
    outputHistory,
    selectedOutput,
    printCandidateOutput,
  } = useCameraRenderOutput();

  const {
    printJobs,
  } = useCameraPrintQueue();

  const {
    recordBoothEvent,
  } = useBoothLifecycleLogger();

  const lastSessionIdRef = useRef<string | null>(null);
  const lastStepKeyRef = useRef('');
  const lastPaymentKeyRef = useRef('');
  const lastCaptureSignatureRef = useRef('');
  const lastOutputCountRef = useRef(0);
  const lastPrintJobCountRef = useRef(0);
  const lastPrintStatusMapRef = useRef<Record<string, string>>({});
  const completedSessionIdsRef = useRef<Set<string>>(new Set());

  const sessionId = session?.id;

  const captureSignature = useMemo(() => {
    return Object.keys(capturedFramesBySlotId).sort().join('|');
  }, [capturedFramesBySlotId]);

  const capturedCount = useMemo(() => {
    return Object.keys(capturedFramesBySlotId).length;
  }, [capturedFramesBySlotId]);

  const printStatusSignature = useMemo(() => {
    return printJobs
      .map((job) => `${job.id}:${job.status}`)
      .sort()
      .join('|');
  }, [printJobs]);

  useEffect(() => {
    if (sessionId && lastSessionIdRef.current !== sessionId) {
      recordBoothEvent({
        type: 'session_started',
        summary: 'Booth session started.',
        sessionId,
        step: currentStep,
        paymentStatus,
        payload: {
          startedAt: session?.startedAt,
        },
      });

      lastSessionIdRef.current = sessionId;
    }

    if (!sessionId && lastSessionIdRef.current) {
      recordBoothEvent({
        type: 'session_reset',
        summary: 'Booth session reset.',
        sessionId: lastSessionIdRef.current,
        payload: {
          previousSessionId: lastSessionIdRef.current,
        },
      });

      lastSessionIdRef.current = null;
      lastStepKeyRef.current = '';
      lastPaymentKeyRef.current = '';
      lastCaptureSignatureRef.current = '';
      lastOutputCountRef.current = 0;
      lastPrintJobCountRef.current = 0;
      lastPrintStatusMapRef.current = {};
    }
  }, [
    currentStep,
    paymentStatus,
    recordBoothEvent,
    session?.startedAt,
    sessionId,
  ]);

  useEffect(() => {
    if (!sessionId) return;

    const stepKey = `${sessionId}:${currentStep}`;

    if (lastStepKeyRef.current === stepKey) return;

    recordBoothEvent({
      type: 'step_changed',
      summary: `Booth step changed to ${currentStep}.`,
      sessionId,
      step: currentStep,
      paymentStatus,
    });

    lastStepKeyRef.current = stepKey;
  }, [
    currentStep,
    paymentStatus,
    recordBoothEvent,
    sessionId,
  ]);

  useEffect(() => {
    if (!sessionId) return;

    const paymentKey = `${sessionId}:${paymentStatus}`;

    if (lastPaymentKeyRef.current === paymentKey) return;

    recordBoothEvent({
      type: 'payment_status_changed',
      summary: `Payment status changed to ${paymentStatus}.`,
      sessionId,
      step: currentStep,
      paymentStatus,
    });

    if (paymentStatus === 'pending') {
      recordBoothEvent({
        type: 'payment_pending',
        summary: 'Payment is waiting for confirmation.',
        sessionId,
        step: currentStep,
        paymentStatus,
      });
    }

    if (paymentStatus === 'confirmed') {
      recordBoothEvent({
        type: 'payment_confirmed',
        summary: 'Payment confirmed and camera unlocked.',
        sessionId,
        step: currentStep,
        paymentStatus,
        payload: {
          paymentConfirmedAt: session?.paymentConfirmedAt,
        },
      });
    }

    if (paymentStatus === 'failed') {
      recordBoothEvent({
        type: 'payment_failed',
        summary: 'Payment marked as failed.',
        sessionId,
        step: currentStep,
        paymentStatus,
      });
    }

    lastPaymentKeyRef.current = paymentKey;
  }, [
    currentStep,
    paymentStatus,
    recordBoothEvent,
    session?.paymentConfirmedAt,
    sessionId,
  ]);

  useEffect(() => {
    if (!sessionId) return;
    if (lastCaptureSignatureRef.current === captureSignature) return;

    if (captureSignature) {
      recordBoothEvent({
        type: 'capture_count_changed',
        summary: `Captured frame count changed to ${capturedCount}.`,
        sessionId,
        step: currentStep,
        paymentStatus,
        payload: {
          capturedCount,
          slotIds: Object.keys(capturedFramesBySlotId).sort(),
        },
      });
    }

    lastCaptureSignatureRef.current = captureSignature;
  }, [
    capturedCount,
    capturedFramesBySlotId,
    captureSignature,
    currentStep,
    paymentStatus,
    recordBoothEvent,
    sessionId,
  ]);

  useEffect(() => {
    if (!sessionId) return;

    if (outputHistory.length > lastOutputCountRef.current) {
      const latestOutput = outputHistory.at(-1);

      recordBoothEvent({
        type: 'render_output_created',
        summary: 'Final render output created.',
        sessionId,
        step: currentStep,
        paymentStatus,
        payload: {
          outputId: latestOutput?.id,
          outputCount: outputHistory.length,
          selectedOutputId: selectedOutput?.id,
          printCandidateOutputId: printCandidateOutput?.id,
        },
      });
    }

    lastOutputCountRef.current = outputHistory.length;
  }, [
    currentStep,
    outputHistory,
    paymentStatus,
    printCandidateOutput?.id,
    recordBoothEvent,
    selectedOutput?.id,
    sessionId,
  ]);

  useEffect(() => {
    if (!sessionId) return;

    if (printJobs.length > lastPrintJobCountRef.current) {
      const latestJob = printJobs.at(-1);

      recordBoothEvent({
        type: 'print_job_created',
        summary: 'Print job created.',
        sessionId,
        step: currentStep,
        paymentStatus,
        payload: {
          jobId: latestJob?.id,
          status: latestJob?.status,
          copies: latestJob?.copies,
          printJobCount: printJobs.length,
        },
      });
    }

    const previousStatusMap = lastPrintStatusMapRef.current;
    const nextStatusMap: Record<string, string> = {};

    for (const job of printJobs) {
      nextStatusMap[job.id] = job.status;

      const previousStatus = previousStatusMap[job.id];

      if (previousStatus && previousStatus !== job.status) {
        if (job.status === 'completed') {
          recordBoothEvent({
            type: 'print_job_completed',
            summary: 'Print job completed.',
            sessionId,
            step: currentStep,
            paymentStatus,
            payload: {
              jobId: job.id,
              copies: job.copies,
              printerName: job.printerName,
            },
          });
        }

        if (job.status === 'failed') {
          recordBoothEvent({
            type: 'print_job_failed',
            summary: 'Print job failed.',
            sessionId,
            step: currentStep,
            paymentStatus,
            payload: {
              jobId: job.id,
              errorMessage: job.errorMessage,
              printerName: job.printerName,
            },
          });
        }
      }
    }

    lastPrintJobCountRef.current = printJobs.length;
    lastPrintStatusMapRef.current = nextStatusMap;
  }, [
    currentStep,
    paymentStatus,
    printJobs,
    printStatusSignature,
    recordBoothEvent,
    sessionId,
  ]);

  useEffect(() => {
    if (!sessionId) return;
    if (currentStep !== 'complete') return;
    if (completedSessionIdsRef.current.has(sessionId)) return;

    completedSessionIdsRef.current.add(sessionId);

    recordBoothEvent({
      type: 'session_completed',
      summary: 'Booth session completed.',
      sessionId,
      step: currentStep,
      paymentStatus,
      payload: {
        completedAt: session?.completedAt,
      },
    });
  }, [
    currentStep,
    paymentStatus,
    recordBoothEvent,
    session?.completedAt,
    sessionId,
  ]);

  return null;
}
TSX

cat > apps/booth-ui/src/booth/BoothLifecycleDebugPanel.tsx <<'TSX'
import React from 'react';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';

function downloadJson(filename: string, data: unknown) {
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json',
  });

  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');

  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();

  URL.revokeObjectURL(url);
}

export function BoothLifecycleDebugPanel() {
  const {
    events,
    latestEvent,
    clearBoothEvents,
  } = useBoothLifecycleLogger();

  const latestEvents = events.slice(-8).reverse();

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Lifecycle Events
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            {events.length} local event(s) recorded.
          </p>

          {latestEvent && (
            <p className="mt-1 text-xs font-bold text-emerald-200">
              Latest: {latestEvent.type}
            </p>
          )}
        </div>

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() =>
              downloadJson(
                `corra-booth-lifecycle-${new Date()
                  .toISOString()
                  .replace(/[:.]/g, '-')}.json`,
                events,
              )
            }
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
          >
            Export JSON
          </button>

          <button
            type="button"
            onClick={clearBoothEvents}
            className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
          >
            Clear Log
          </button>
        </div>
      </div>

      <div className="mt-4 grid gap-2">
        {latestEvents.length === 0 && (
          <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">
            No lifecycle events yet.
          </div>
        )}

        {latestEvents.map((event) => (
          <div
            key={event.id}
            className="rounded-2xl bg-white/10 p-3"
          >
            <div className="flex flex-col gap-1 sm:flex-row sm:items-start sm:justify-between">
              <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                {event.type}
              </p>

              <p className="font-mono text-[10px] font-bold text-white/40">
                {new Date(event.at).toLocaleTimeString()}
              </p>
            </div>

            <p className="mt-1 text-xs font-semibold text-white/60">
              {event.summary}
            </p>

            <p className="mt-1 break-all font-mono text-[10px] font-bold text-white/35">
              {event.sessionId || 'no-session'} · {event.step || 'no-step'} ·{' '}
              {event.paymentStatus || 'no-payment'}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
TSX

cat > apps/booth-ui/src/booth/BoothRuntimeProviders.tsx <<'TSX'
import React, { type ReactNode } from 'react';
import {
  CameraCaptureGuideProvider,
  CameraPrintQueueProvider,
  CameraRenderOutputProvider,
  CapturedFramesProvider,
} from '../camera';
import { BoothFlowProvider } from './BoothFlowProvider';
import { BoothLifecycleAutoTracker } from './BoothLifecycleAutoTracker';
import { BoothLifecycleLoggerProvider } from './BoothLifecycleLoggerProvider';

type BoothRuntimeProvidersProps = {
  children: ReactNode;
};

export function BoothRuntimeProviders({
  children,
}: BoothRuntimeProvidersProps) {
  return (
    <BoothFlowProvider>
      <BoothLifecycleLoggerProvider>
        <CameraCaptureGuideProvider>
          <CapturedFramesProvider>
            <CameraRenderOutputProvider>
              <CameraPrintQueueProvider>
                <BoothLifecycleAutoTracker />
                {children}
              </CameraPrintQueueProvider>
            </CameraRenderOutputProvider>
          </CapturedFramesProvider>
        </CameraCaptureGuideProvider>
      </BoothLifecycleLoggerProvider>
    </BoothFlowProvider>
  );
}
TSX

cat > apps/booth-ui/src/booth/BoothPaymentStep.tsx <<TSX
import React from 'react';
import { usePaymentSettings } from '$PAYMENT_IMPORT';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';
import { useBoothFlow } from './BoothFlowProvider';

function formatIdr(value: unknown) {
  const numberValue =
    typeof value === 'number'
      ? value
      : typeof value === 'string'
        ? Number(value.replace(/[^0-9.-]+/g, ''))
        : 0;

  if (!Number.isFinite(numberValue) || numberValue <= 0) {
    return 'Price not set';
  }

  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(numberValue);
}

function readFirstString(
  settings: Record<string, unknown>,
  keys: string[],
  fallback: string,
) {
  for (const key of keys) {
    const value = settings[key];

    if (typeof value === 'string' && value.trim()) {
      return value;
    }
  }

  return fallback;
}

function readFirstValue(
  settings: Record<string, unknown>,
  keys: string[],
): unknown {
  for (const key of keys) {
    const value = settings[key];

    if (value !== undefined && value !== null && value !== '') {
      return value;
    }
  }

  return undefined;
}

function getPaymentSettingsObject(context: unknown): Record<string, unknown> {
  const value = context as {
    settings?: Record<string, unknown>;
    paymentSettings?: Record<string, unknown>;
    payment?: Record<string, unknown>;
    config?: Record<string, unknown>;
  };

  return (
    value.settings ||
    value.paymentSettings ||
    value.payment ||
    value.config ||
    {}
  );
}

function getPaymentStatusStyle(status: string) {
  if (status === 'confirmed') {
    return {
      card: 'bg-emerald-50',
      label: 'text-emerald-500',
      text: 'text-emerald-800',
      badge: 'bg-emerald-600',
    };
  }

  if (status === 'pending') {
    return {
      card: 'bg-blue-50',
      label: 'text-blue-500',
      text: 'text-blue-800',
      badge: 'bg-blue-600',
    };
  }

  if (status === 'failed') {
    return {
      card: 'bg-red-50',
      label: 'text-red-500',
      text: 'text-red-800',
      badge: 'bg-red-600',
    };
  }

  return {
    card: 'bg-violet-50',
    label: 'text-violet-500',
    text: 'text-violet-800',
    badge: 'bg-violet-600',
  };
}

export function BoothPaymentStep() {
  const {
    session,
    paymentStatus,
    markPaymentPending,
    markPaymentConfirmed,
    markPaymentFailed,
    setStep,
  } = useBoothFlow();

  const {
    recordBoothEvent,
  } = useBoothLifecycleLogger();

  const paymentContext = usePaymentSettings() as unknown;
  const settings = getPaymentSettingsObject(paymentContext);

  const merchantName = readFirstString(
    settings,
    [
      'merchantName',
      'businessName',
      'storeName',
      'brandName',
      'displayName',
    ],
    'Corra Booth',
  );

  const provider = readFirstString(
    settings,
    [
      'provider',
      'activeProvider',
      'paymentProvider',
      'defaultProvider',
      'method',
    ],
    'Payment Provider',
  );

  const priceValue = readFirstValue(settings, [
    'sessionPrice',
    'sessionPriceIdr',
    'photoSessionPrice',
    'price',
    'priceAmount',
    'amount',
    'amountIdr',
    'basePrice',
    'defaultAmount',
  ]);

  const staticQrisImage = readFirstString(
    settings,
    [
      'staticQrisDataUrl',
      'qrisDataUrl',
      'qrisImageUrl',
      'staticQrisImageUrl',
      'qrisAssetUrl',
      'staticQrisUrl',
      'qrisUrl',
    ],
    '',
  );

  const statusStyle = getPaymentStatusStyle(paymentStatus);

  const handleStartPayment = () => {
    markPaymentPending();

    recordBoothEvent({
      type: 'payment_pending',
      summary: 'Customer started payment flow.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'pending',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });
  };

  const handleConfirmPayment = () => {
    recordBoothEvent({
      type: 'payment_confirmed',
      summary: 'Payment manually confirmed from booth payment screen.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'confirmed',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });

    markPaymentConfirmed();
  };

  const handleFailPayment = () => {
    recordBoothEvent({
      type: 'payment_failed',
      summary: 'Payment manually marked as failed from booth payment screen.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'failed',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });

    markPaymentFailed();
  };

  const handleRetryPayment = () => {
    markPaymentPending();

    recordBoothEvent({
      type: 'payment_pending',
      summary: 'Customer retried payment flow.',
      sessionId: session?.id,
      step: 'payment',
      paymentStatus: 'pending',
      payload: {
        provider,
        merchantName,
        priceValue,
      },
    });
  };

  return (
    <div className="mt-4 grid gap-6 lg:grid-cols-[0.9fr_1.1fr] lg:items-stretch">
      <aside className="rounded-[2rem] bg-white p-6 text-slate-950">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.25em] text-blue-500">
              Payment
            </p>

            <h4 className="mt-3 text-5xl font-black leading-none">
              Complete Payment
            </h4>
          </div>

          <span
            className={\`rounded-full px-3 py-1 text-xs font-black uppercase text-white \${statusStyle.badge}\`}
          >
            {paymentStatus}
          </span>
        </div>

        <p className="mt-4 text-sm font-bold leading-relaxed text-slate-600">
          Selesaikan pembayaran untuk membuka sesi camera. Status payment
          sekarang punya state idle, pending, confirmed, dan failed.
        </p>

        <div className="mt-6 grid gap-3">
          <div className="rounded-3xl bg-slate-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Merchant
            </p>
            <p className="mt-2 text-xl font-black text-slate-950">
              {merchantName}
            </p>
          </div>

          <div className="rounded-3xl bg-blue-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
              Session Price
            </p>
            <p className="mt-2 text-3xl font-black text-blue-700">
              {formatIdr(priceValue)}
            </p>
          </div>

          <div className="rounded-3xl bg-emerald-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
              Active Provider
            </p>
            <p className="mt-2 text-lg font-black text-emerald-800">
              {provider}
            </p>
          </div>

          <div className={\`rounded-3xl p-4 \${statusStyle.card}\`}>
            <p className={\`text-xs font-black uppercase tracking-[0.2em] \${statusStyle.label}\`}>
              Payment Status
            </p>
            <p className={\`mt-2 text-lg font-black uppercase \${statusStyle.text}\`}>
              {paymentStatus}
            </p>
          </div>
        </div>

        {paymentStatus === 'idle' && (
          <div className="mt-6 rounded-3xl bg-violet-50 p-4">
            <p className="text-sm font-black text-violet-900">
              Ready to start payment.
            </p>
            <p className="mt-1 text-xs font-bold text-violet-700">
              Customer akan masuk ke waiting state setelah menekan Start
              Payment.
            </p>
          </div>
        )}

        {paymentStatus === 'pending' && (
          <div className="mt-6 rounded-3xl bg-blue-50 p-4">
            <div className="flex items-center gap-3">
              <div className="h-4 w-4 animate-pulse rounded-full bg-blue-600" />
              <p className="text-sm font-black text-blue-900">
                Waiting for payment confirmation...
              </p>
            </div>
            <p className="mt-2 text-xs font-bold text-blue-700">
              Untuk Static QRIS/manual mode, operator/customer bisa confirm
              manual. Untuk DOKU nanti state ini bisa dipolling dari transaction
              status.
            </p>
          </div>
        )}

        {paymentStatus === 'failed' && (
          <div className="mt-6 rounded-3xl bg-red-50 p-4">
            <p className="text-sm font-black text-red-900">
              Payment failed or cancelled.
            </p>
            <p className="mt-1 text-xs font-bold text-red-700">
              Customer bisa retry payment atau kembali ke welcome.
            </p>
          </div>
        )}

        <div className="mt-6 grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => setStep('welcome')}
            className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            Back
          </button>

          {paymentStatus === 'idle' && (
            <button
              type="button"
              onClick={handleStartPayment}
              className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
            >
              Start Payment
            </button>
          )}

          {paymentStatus === 'pending' && (
            <button
              type="button"
              onClick={handleConfirmPayment}
              className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
            >
              Confirm Payment
            </button>
          )}

          {paymentStatus === 'failed' && (
            <button
              type="button"
              onClick={handleRetryPayment}
              className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
            >
              Retry Payment
            </button>
          )}
        </div>

        {paymentStatus === 'pending' && (
          <div className="mt-3 grid gap-3 sm:grid-cols-2">
            <button
              type="button"
              onClick={handleFailPayment}
              className="rounded-3xl border border-red-200 bg-red-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-red-700"
            >
              Mark Failed
            </button>

            <button
              type="button"
              onClick={handleRetryPayment}
              className="rounded-3xl border border-blue-200 bg-blue-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-blue-700"
            >
              Restart Waiting
            </button>
          </div>
        )}
      </aside>

      <section className="rounded-[2rem] border border-white/10 bg-white/10 p-6">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
          Payment Display
        </p>

        {staticQrisImage ? (
          <div className="mt-4 rounded-[2rem] bg-white p-6 text-center text-slate-950">
            <p className="text-sm font-black uppercase tracking-[0.2em] text-slate-400">
              Scan QRIS
            </p>

            <img
              src={staticQrisImage}
              alt="Static QRIS"
              className="mx-auto mt-5 max-h-[360px] rounded-3xl border border-slate-200 bg-white object-contain"
            />

            <p className="mt-4 text-sm font-bold text-slate-500">
              Setelah pembayaran berhasil, tekan Confirm Payment.
            </p>
          </div>
        ) : (
          <div className="mt-4 flex min-h-[420px] flex-col items-center justify-center rounded-[2rem] border border-dashed border-white/20 bg-black/20 p-6 text-center">
            <p className="text-5xl font-black">QRIS</p>
            <p className="mt-3 max-w-md text-sm font-semibold text-white/60">
              Static QRIS belum terdeteksi dari payment settings. Untuk sekarang
              customer bisa dikonfirmasi manual lewat tombol Start Payment lalu
              Confirm Payment.
            </p>
          </div>
        )}

        <div className="mt-4 rounded-3xl bg-black/20 p-4">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Payment Gate
          </p>
          <p className="mt-2 text-sm font-semibold text-white/60">
            Status pending adalah tempat nanti DOKU polling / webhook / admin
            confirmation disambungkan. Saat confirmed, flow otomatis masuk ke
            Camera step.
          </p>
        </div>
      </section>
    </div>
  );
}
TSX

cat > apps/booth-ui/src/booth/BoothCustomerScreen.tsx <<'TSX'
import React from 'react';
import {
  boothFlowStepLabels,
  boothFlowSteps,
  type BoothFlowStep,
} from './booth-flow-types';
import { BoothCameraStep } from './BoothCameraStep';
import { BoothCompleteStep } from './BoothCompleteStep';
import { BoothDeliveryStep } from './BoothDeliveryStep';
import { BoothLifecycleDebugPanel } from './BoothLifecycleDebugPanel';
import { BoothPaymentStep } from './BoothPaymentStep';
import { BoothReviewStep } from './BoothReviewStep';
import { BoothStepErrorBoundary } from './BoothStepErrorBoundary';
import { BoothStepGuard } from './BoothStepGuard';
import { BoothWelcomeStep } from './BoothWelcomeStep';
import { useBoothFlow } from './BoothFlowProvider';

type BoothCustomerScreenProps = {
  showDevNavigation?: boolean;
  showHeader?: boolean;
};

const stepDescriptions: Record<BoothFlowStep, string> = {
  welcome: 'Customer mulai dari layar sambutan sebelum masuk ke pembayaran.',
  payment: 'Customer menyelesaikan payment gate sebelum camera dibuka.',
  camera: 'Customer melakukan countdown capture sesuai layout aktif.',
  review: 'Customer melihat hasil render final dan bisa retake jika perlu.',
  delivery: 'Customer memilih print / download / QR delivery.',
  complete: 'Session selesai dan booth siap di-reset untuk customer berikutnya.',
};

function renderStep(currentStep: BoothFlowStep) {
  if (currentStep === 'welcome') return <BoothWelcomeStep />;
  if (currentStep === 'payment') return <BoothPaymentStep />;
  if (currentStep === 'camera') return <BoothCameraStep />;
  if (currentStep === 'review') return <BoothReviewStep />;
  if (currentStep === 'delivery') return <BoothDeliveryStep />;
  if (currentStep === 'complete') return <BoothCompleteStep />;

  return <BoothWelcomeStep />;
}

export function BoothCustomerScreen({
  showDevNavigation = false,
  showHeader = true,
}: BoothCustomerScreenProps) {
  const {
    session,
    currentStep,
    currentStepIndex,
    isFirstStep,
    isLastStep,
    startSession,
    setStep,
    canAccessStep,
    goNext,
    goBack,
    completeSession,
    resetSession,
    paymentStatus,
    paymentConfirmed,
  } = useBoothFlow();

  const progressPercent =
    ((currentStepIndex + 1) / boothFlowSteps.length) * 100;

  return (
    <div className="overflow-hidden rounded-[2rem] border border-slate-200 bg-slate-950 text-white shadow-sm">
      <div className="bg-[radial-gradient(circle_at_top_left,rgba(59,130,246,0.35),transparent_35%),radial-gradient(circle_at_bottom_right,rgba(16,185,129,0.25),transparent_35%)] p-6">
        {showHeader && (
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

            <div className="flex flex-wrap gap-2">
              <span className="rounded-full bg-white px-4 py-2 text-xs font-black text-slate-950">
                {session ? 'Session Active' : 'No Session'}
              </span>

              <span
                className={`rounded-full px-4 py-2 text-xs font-black text-white ${
                  paymentConfirmed ? 'bg-emerald-600' : 'bg-amber-500'
                }`}
              >
                {paymentConfirmed ? 'Payment Confirmed' : 'Payment Locked'}
              </span>
            </div>
          </div>
        )}

        <div className={showHeader ? 'mt-6' : ''}>
          <div className="h-3 overflow-hidden rounded-full bg-white/15">
            <div
              className="h-full rounded-full bg-white"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        </div>

        {showDevNavigation && (
          <div className="mt-4 rounded-3xl border border-white/10 bg-black/20 p-4">
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
                  Developer Navigation
                </p>
                <p className="mt-1 text-xs font-bold text-white/50">
                  Only visible in admin preview or booth dev mode.
                </p>
              </div>

              <span className="rounded-full bg-violet-500 px-3 py-1 text-xs font-black text-white">
                DEV MODE
              </span>
            </div>

            <div className="mt-4 grid gap-2 sm:grid-cols-6">
              {boothFlowSteps.map((step, index) => {
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
              })}
            </div>

            <div className="mt-4 grid gap-3 sm:grid-cols-4">
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

            <div className="mt-4 rounded-2xl bg-black/20 p-3 font-mono text-[11px] font-bold text-white/60">
              <p>Payment status: {paymentStatus}</p>
              <p>Session ID: {session?.id || 'none'}</p>
            </div>

            <div className="mt-4">
              <BoothLifecycleDebugPanel />
            </div>
          </div>
        )}

        {!showDevNavigation && (
          <div className="mt-4 rounded-3xl border border-white/10 bg-black/20 p-4">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
                  Booth Progress
                </p>
                <p className="mt-1 text-sm font-bold text-white/70">
                  Step {currentStepIndex + 1} of {boothFlowSteps.length} ·{' '}
                  {boothFlowStepLabels[currentStep]}
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
        )}

        <div className="mt-6 rounded-3xl bg-white/10 p-5">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/50">
            Current Customer Screen
          </p>

          <BoothStepErrorBoundary>
            <BoothStepGuard>{renderStep(currentStep)}</BoothStepGuard>
          </BoothStepErrorBoundary>
        </div>
      </div>
    </div>
  );
}
TSX

INDEX="apps/booth-ui/src/booth/index.ts"
grep -q "booth-lifecycle-types" "$INDEX" || cat >> "$INDEX" <<'TS'
export * from './booth-lifecycle-types';
export * from './booth-lifecycle-storage';
export * from './BoothLifecycleLoggerProvider';
export * from './BoothLifecycleAutoTracker';
export * from './BoothLifecycleDebugPanel';
TS

echo ""
echo "Relevant lines:"
grep -R "BoothLifecycle\\|payment_pending\\|Start Payment\\|Lifecycle Events" -n apps/booth-ui/src/booth || true

echo ""
echo "9B12-13 combined done."
