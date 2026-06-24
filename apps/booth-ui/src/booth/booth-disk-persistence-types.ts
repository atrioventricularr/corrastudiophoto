export type BoothDiskAssetKind =
  | 'raw_capture'
  | 'final_output'
  | 'print_ready'
  | 'manifest'
  | 'export'
  | 'other';

export type BoothDiskSaveDataUrlInput = {
  sessionId: string;
  kind: BoothDiskAssetKind | string;
  filename: string;
  dataUrl: string;
  metadata?: Record<string, unknown>;
};

export type BoothDiskSaveTextInput = {
  sessionId: string;
  kind: BoothDiskAssetKind | string;
  filename: string;
  text: string;
  mimeType?: string;
  metadata?: Record<string, unknown>;
};

export type BoothDiskFileRecord = {
  ok?: boolean;
  id: string;
  sessionId: string;
  kind: string;
  filename: string;
  mimeType?: string;
  sizeBytes: number;
  absolutePath?: string;
  relativePath: string;
  savedAt: string;
  metadata?: Record<string, unknown>;
};

export type BoothDiskListResult = {
  ok: boolean;
  rootPath?: string;
  files: Array<{
    path?: string;
    relativePath: string;
    filename: string;
    sizeBytes: number;
    modifiedAt: string;
  }>;
  error?: string;
};

export type BoothDiskActionResult = {
  ok: boolean;
  path?: string;
  rootPath?: string;
  relativePath?: string;
  deletedCount?: number;
  error?: string;
};

export type CorraDiskBridge = {
  getRoot: () => Promise<BoothDiskActionResult>;
  openOutputFolder: (payload?: { sessionId?: string }) => Promise<BoothDiskActionResult>;
  saveDataUrl: (payload: BoothDiskSaveDataUrlInput) => Promise<BoothDiskFileRecord>;
  saveTextFile: (payload: BoothDiskSaveTextInput) => Promise<BoothDiskFileRecord>;
  listSessionFiles: (payload?: { sessionId?: string }) => Promise<BoothDiskListResult>;
  deleteFile: (payload: { relativePath: string }) => Promise<BoothDiskActionResult>;
  cleanupOlderThanDays: (payload: { days: number }) => Promise<BoothDiskActionResult>;
};

declare global {
  interface Window {
    corraDisk?: CorraDiskBridge;
  }
}
