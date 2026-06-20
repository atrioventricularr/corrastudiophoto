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
