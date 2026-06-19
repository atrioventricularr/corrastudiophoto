#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1I - Template Schema Foundation"
echo "========================================"

mkdir -p apps/booth-ui/src/templates

cat > apps/booth-ui/src/templates/types.ts <<'TS'
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
TS

cat > apps/booth-ui/src/templates/template-utils.ts <<'TS'
import type {
  PhotoTemplate,
  PhotoTemplateLayer,
  TemplateAssetKind,
  TemplateAssetRef,
  TemplatePaperSnapshot,
  TemplatePrinterSnapshot,
} from './types';

function createId(prefix: string): string {
  const random =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(16).slice(2)}`;

  return `${prefix}-${random}`;
}

export function createTemplateAsset(input: {
  kind: TemplateAssetKind;
  source?: 'local' | 'supabase' | 'public-url';
  name: string;
  url?: string;
  localPath?: string;
  bucket?: string;
  objectPath?: string;
  mimeType?: string;
  widthPx?: number;
  heightPx?: number;
  fileSizeBytes?: number;
}): TemplateAssetRef {
  return {
    id: createId('asset'),
    kind: input.kind,
    source: input.source || 'local',
    name: input.name,
    url: input.url,
    localPath: input.localPath,
    bucket: input.bucket,
    objectPath: input.objectPath,
    mimeType: input.mimeType,
    widthPx: input.widthPx,
    heightPx: input.heightPx,
    fileSizeBytes: input.fileSizeBytes,
  };
}

export function createTemplateLayer(input: {
  name: string;
  assetId: string;
  kind: TemplateAssetKind;
  zIndex?: number;
  opacity?: number;
  visible?: boolean;
}): PhotoTemplateLayer {
  return {
    id: createId('layer'),
    name: input.name,
    assetId: input.assetId,
    kind: input.kind,

    visible: input.visible ?? true,
    opacity: input.opacity ?? 1,
    zIndex: input.zIndex ?? 10,

    xPercent: 0,
    yPercent: 0,
    widthPercent: 100,
    heightPercent: 100,

    rotationDeg: 0,
  };
}

export function createPhotoTemplate(input: {
  name: string;
  customerFacingName?: string;
  layoutId: string;
  layoutName: string;
  paperSnapshot: TemplatePaperSnapshot;
  printerSnapshot?: TemplatePrinterSnapshot;
  assets?: TemplateAssetRef[];
  layers?: PhotoTemplateLayer[];
  frameOverlayAssetId?: string;
  backgroundAssetId?: string;
  previewAssetId?: string;
  tags?: string[];
  notes?: string;
}): PhotoTemplate {
  const now = new Date().toISOString();

  return {
    id: createId('template'),
    name: input.name,
    customerFacingName: input.customerFacingName || input.name,
    status: 'draft',

    layoutId: input.layoutId,
    layoutName: input.layoutName,

    paperSnapshot: input.paperSnapshot,
    printerSnapshot: input.printerSnapshot,

    assets: input.assets || [],
    layers: input.layers || [],

    frameOverlayAssetId: input.frameOverlayAssetId,
    backgroundAssetId: input.backgroundAssetId,
    previewAssetId: input.previewAssetId,

    tags: input.tags || [],
    notes: input.notes,

    createdAt: now,
    updatedAt: now,
  };
}

export function activateTemplate(template: PhotoTemplate): PhotoTemplate {
  return {
    ...template,
    status: 'active',
    updatedAt: new Date().toISOString(),
  };
}

export function archiveTemplate(template: PhotoTemplate): PhotoTemplate {
  return {
    ...template,
    status: 'archived',
    updatedAt: new Date().toISOString(),
  };
}
TS

cat > apps/booth-ui/src/templates/index.ts <<'TS'
export * from './types';
export * from './template-utils';
TS

echo ""
echo "Created:"
echo "- apps/booth-ui/src/templates/types.ts"
echo "- apps/booth-ui/src/templates/template-utils.ts"
echo "- apps/booth-ui/src/templates/index.ts"
echo ""
echo "Phase 10D1I completed."
