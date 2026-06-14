export type OfflineQueueJobType =
  | "UPLOAD_ASSET"
  | "SAVE_PHOTO_SESSION"
  | "SAVE_TRANSACTION_LOG"
  | "VERIFY_LICENSE"
  | "SYNC_SETTINGS";

export type OfflineQueueJobStatus =
  | "PENDING"
  | "PROCESSING"
  | "COMPLETED"
  | "FAILED";

export interface OfflineQueueJob<TPayload = unknown> {
  id: string;
  type: OfflineQueueJobType;
  status: OfflineQueueJobStatus;
  payload: TPayload;
  retryCount: number;
  lastError: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface OfflineQueueRepository {
  enqueue<TPayload>(job: OfflineQueueJob<TPayload>): Promise<void>;
  listPending(limit?: number): Promise<Array<OfflineQueueJob<unknown>>>;
  markProcessing(jobId: string): Promise<void>;
  markCompleted(jobId: string): Promise<void>;
  markFailed(jobId: string, errorMessage: string): Promise<void>;
}
