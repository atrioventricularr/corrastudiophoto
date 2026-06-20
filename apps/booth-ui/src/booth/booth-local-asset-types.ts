export type BoothLocalAssetKind =
  | 'raw_capture'
  | 'final_output';

export type BoothLocalAssetRecord = {
  id: string;
  sessionId: string;
  kind: BoothLocalAssetKind;
  dataUrl: string;
  filename: string;
  mimeType: string;
  sizeBytes: number;
  createdAt: string;
  updatedAt: string;
  slotId?: string;
  outputId?: string;
  templateId?: string;
  templateName?: string;
  layoutId?: string;
  layoutName?: string;
  renderMode?: string;
  widthPx?: number;
  heightPx?: number;
  source?: string;
  metadata?: Record<string, unknown>;
};

export type SaveBoothLocalAssetInput = {
  sessionId: string;
  kind: BoothLocalAssetKind;
  dataUrl: string;
  filename?: string;
  mimeType?: string;
  slotId?: string;
  outputId?: string;
  templateId?: string;
  templateName?: string;
  layoutId?: string;
  layoutName?: string;
  renderMode?: string;
  widthPx?: number;
  heightPx?: number;
  source?: string;
  metadata?: Record<string, unknown>;
};

export type BoothLocalAssetSummary = {
  totalAssets: number;
  rawCaptureCount: number;
  finalOutputCount: number;
  totalSizeBytes: number;
};
