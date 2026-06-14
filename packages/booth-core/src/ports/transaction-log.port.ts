export interface TransactionLogEntry {
  id: string;
  sessionId?: string;
  type:
    | "LICENSE_VERIFIED"
    | "PHOTO_SESSION_STARTED"
    | "PHOTO_CAPTURED"
    | "FRAME_COMPOSED"
    | "ASSET_UPLOADED"
    | "PRINT_REQUESTED"
    | "ERROR";
  message: string;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

export interface TransactionLogPort {
  append(entry: TransactionLogEntry): Promise<void>;
}
