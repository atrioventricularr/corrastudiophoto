import type {
  PaperPresetId,
  PrintMarginPx,
  PrintOffsetPx,
  PrintOrientation,
  PrinterType,
} from '../print';

export type PhotoTemplateStatus =
  | 'draft'
  | 'active'
  | 'archived';

export type TemplateAssetSource =
  | 'local'
  | 'supabase'
  | 'public-url';

export type TemplateAssetKind =
  | 'frame-overlay'
  | 'background'
  | 'watermark'
  | 'sticker'
  | 'sample-preview';

export type TemplateAssetRef = {
  id: string;
  kind: TemplateAssetKind;
  source: TemplateAssetSource;

  name: string;
  mimeType?: string;

  /**
   * Browser/public URL, Supabase public URL, or corra-asset:// local URL.
   */
  url?: string;

  /**
   * Local absolute path handled by Electron.
   * Do not expose this directly to browser-only flows.
   */
  localPath?: string;

  /**
   * Supabase storage reference.
   */
  bucket?: string;
  objectPath?: string;

  widthPx?: number;
  heightPx?: number;
  fileSizeBytes?: number;
};

export type TemplatePaperSnapshot = {
  paperPresetId: PaperPresetId;
  paperName: string;
  paperWidthInch: number;
  paperHeightInch: number;
  orientation: PrintOrientation;
  dpi: number;
  canvasWidthPx: number;
  canvasHeightPx: number;
};

export type TemplatePrinterSnapshot = {
  printerProfileId: string;
  printerProfileName: string;

  printerType: PrinterType;
  printerModel: string;

  borderless: boolean;
  rotateBeforePrint: boolean;

  marginPx: PrintMarginPx;
  offsetPx: PrintOffsetPx;
  scalePercent: number;
};

export type PhotoTemplateLayer = {
  id: string;
  name: string;
  assetId: string;
  kind: TemplateAssetKind;

  visible: boolean;
  opacity: number;
  zIndex: number;

  xPercent: number;
  yPercent: number;
  widthPercent: number;
  heightPercent: number;

  rotationDeg: number;
};

export type PhotoTemplate = {
  id: string;
  name: string;
  customerFacingName: string;
  status: PhotoTemplateStatus;

  /**
   * Layout determines paper size, canvas size, photo slots,
   * and camera guide positions.
   */
  layoutId: string;
  layoutName: string;

  /**
   * Snapshot is stored so old templates do not break
   * if layout/printer profile changes later.
   */
  paperSnapshot: TemplatePaperSnapshot;
  printerSnapshot?: TemplatePrinterSnapshot;

  assets: TemplateAssetRef[];
  layers: PhotoTemplateLayer[];

  frameOverlayAssetId?: string;
  backgroundAssetId?: string;
  previewAssetId?: string;

  tags: string[];
  notes?: string;

  createdAt: string;
  updatedAt: string;
};
