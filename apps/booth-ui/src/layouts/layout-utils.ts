import {
  calculateCanvasPixelSize,
  findPaperPreset,
  type PaperPresetId,
  type PrintOrientation,
} from '../print';
import type {
  PhotoLayout,
  PhotoLayoutSlot,
} from './types';

export function createLayoutSlot(input: Partial<PhotoLayoutSlot>): PhotoLayoutSlot {
  const id = input.id || `slot-${Date.now()}-${Math.random().toString(16).slice(2)}`;

  return {
    id,
    name: input.name || id,
    captureOrder: input.captureOrder || 1,

    xPercent: input.xPercent ?? 10,
    yPercent: input.yPercent ?? 10,
    widthPercent: input.widthPercent ?? 80,
    heightPercent: input.heightPercent ?? 80,

    shape: input.shape || 'rectangle',
    borderRadiusPercent: input.borderRadiusPercent ?? 4,
    rotationDeg: input.rotationDeg ?? 0,
    cropMode: input.cropMode || 'cover',

    guideLabel: input.guideLabel || input.name || id,
    showGuide: input.showGuide ?? true,
  };
}

export function createPhotoLayout(input: {
  id: string;
  name: string;
  mode?: 'fixed' | 'custom';
  paperPresetId?: PaperPresetId;
  orientation?: PrintOrientation;
  dpi?: number;
  slots: PhotoLayoutSlot[];
  backgroundColor?: string;
  notes?: string;
}): PhotoLayout {
  const paperPreset = findPaperPreset(input.paperPresetId || '4r');
  const dpi = input.dpi || paperPreset.recommendedDpi;
  const orientation = input.orientation || 'portrait';

  const canvas = calculateCanvasPixelSize({
    widthInch: paperPreset.widthInch,
    heightInch: paperPreset.heightInch,
    dpi,
    orientation,
  });

  const now = new Date().toISOString();

  return {
    id: input.id,
    name: input.name,
    mode: input.mode || 'fixed',

    paperPresetId: paperPreset.id,
    paperName: paperPreset.name,
    paperWidthInch: paperPreset.widthInch,
    paperHeightInch: paperPreset.heightInch,
    orientation,
    dpi,

    canvasWidthPx: canvas.widthPx,
    canvasHeightPx: canvas.heightPx,

    backgroundColor: input.backgroundColor || '#ffffff',
    slots: input.slots,

    notes: input.notes,
    createdAt: now,
    updatedAt: now,
  };
}
