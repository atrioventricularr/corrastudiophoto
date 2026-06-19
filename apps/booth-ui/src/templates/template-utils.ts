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
