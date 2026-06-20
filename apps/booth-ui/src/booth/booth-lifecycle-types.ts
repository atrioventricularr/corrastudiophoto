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
