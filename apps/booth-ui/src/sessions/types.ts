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

export type SessionLifecycleSyncStatus =
  | 'idle'
  | 'skipped'
  | 'syncing'
  | 'synced'
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
  syncStatus: SessionLifecycleSyncStatus;
  lastSyncedAt: string | null;
  syncError: string | null;
  syncCurrentSession: () => Promise<void>;
  clearSessionHistory: () => void;
};
