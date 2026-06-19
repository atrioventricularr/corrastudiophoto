import type {
  PaperPresetId,
  PrintOrientation,
} from '../print';

export type PhotoLayoutMode = 'fixed' | 'custom';

export type PhotoSlotShape =
  | 'rectangle'
  | 'square'
  | 'circle';

export type PhotoSlotCropMode =
  | 'cover'
  | 'contain'
  | 'fill';

export type PhotoLayoutSlot = {
  id: string;
  name: string;

  captureOrder: number;

  xPercent: number;
  yPercent: number;
  widthPercent: number;
  heightPercent: number;

  shape: PhotoSlotShape;
  borderRadiusPercent: number;
  rotationDeg: number;
  cropMode: PhotoSlotCropMode;

  guideLabel: string;
  showGuide: boolean;
};

export type PhotoLayout = {
  id: string;
  name: string;
  mode: PhotoLayoutMode;

  paperPresetId: PaperPresetId;
  paperName: string;
  paperWidthInch: number;
  paperHeightInch: number;
  orientation: PrintOrientation;
  dpi: number;

  canvasWidthPx: number;
  canvasHeightPx: number;

  backgroundColor: string;
  slots: PhotoLayoutSlot[];

  notes?: string;
  createdAt: string;
  updatedAt: string;
};

export type LayoutGuideSettings = {
  showGrid: boolean;
  showSlotGuide: boolean;
  guideOpacity: number;
  mirrorPreview: boolean;
  mirrorFinalOutput: boolean;
};
