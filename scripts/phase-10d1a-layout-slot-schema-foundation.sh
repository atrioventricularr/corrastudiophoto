#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1A - Layout Slot Schema"
echo "========================================"

mkdir -p apps/booth-ui/src/layouts

cat > apps/booth-ui/src/layouts/types.ts <<'TS'
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
TS

cat > apps/booth-ui/src/layouts/layout-utils.ts <<'TS'
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
TS

cat > apps/booth-ui/src/layouts/default-layouts.ts <<'TS'
import {
  createLayoutSlot,
  createPhotoLayout,
} from './layout-utils';
import type {
  LayoutGuideSettings,
  PhotoLayout,
} from './types';

export const defaultLayoutGuideSettings: LayoutGuideSettings = {
  showGrid: true,
  showSlotGuide: true,
  guideOpacity: 0.65,
  mirrorPreview: true,
  mirrorFinalOutput: false,
};

export const defaultPhotoLayouts: PhotoLayout[] = [
  createPhotoLayout({
    id: 'fixed-4r-four-grid',
    name: '4R Four Grid',
    mode: 'fixed',
    paperPresetId: '4r',
    orientation: 'portrait',
    slots: [
      createLayoutSlot({
        id: 'slot-1',
        name: 'Photo 1',
        captureOrder: 1,
        xPercent: 8,
        yPercent: 6,
        widthPercent: 40,
        heightPercent: 40,
        shape: 'rectangle',
        guideLabel: 'Pose 1',
      }),
      createLayoutSlot({
        id: 'slot-2',
        name: 'Photo 2',
        captureOrder: 2,
        xPercent: 52,
        yPercent: 6,
        widthPercent: 40,
        heightPercent: 40,
        shape: 'rectangle',
        guideLabel: 'Pose 2',
      }),
      createLayoutSlot({
        id: 'slot-3',
        name: 'Photo 3',
        captureOrder: 3,
        xPercent: 8,
        yPercent: 54,
        widthPercent: 40,
        heightPercent: 40,
        shape: 'rectangle',
        guideLabel: 'Pose 3',
      }),
      createLayoutSlot({
        id: 'slot-4',
        name: 'Photo 4',
        captureOrder: 4,
        xPercent: 52,
        yPercent: 54,
        widthPercent: 40,
        heightPercent: 40,
        shape: 'rectangle',
        guideLabel: 'Pose 4',
      }),
    ],
    notes: 'Default 4R four-photo grid.',
  }),

  createPhotoLayout({
    id: 'fixed-4r-two-strip',
    name: '4R Two Strip',
    mode: 'fixed',
    paperPresetId: '4r',
    orientation: 'portrait',
    slots: [
      createLayoutSlot({
        id: 'strip-slot-1',
        name: 'Top Photo',
        captureOrder: 1,
        xPercent: 10,
        yPercent: 8,
        widthPercent: 80,
        heightPercent: 38,
        shape: 'rectangle',
        guideLabel: 'Top Pose',
      }),
      createLayoutSlot({
        id: 'strip-slot-2',
        name: 'Bottom Photo',
        captureOrder: 2,
        xPercent: 10,
        yPercent: 54,
        widthPercent: 80,
        heightPercent: 38,
        shape: 'rectangle',
        guideLabel: 'Bottom Pose',
      }),
    ],
    notes: 'Default 4R two-photo strip.',
  }),

  createPhotoLayout({
    id: 'custom-a3-event-poster',
    name: 'A3 Event Poster Custom',
    mode: 'custom',
    paperPresetId: 'a3',
    orientation: 'portrait',
    slots: [
      createLayoutSlot({
        id: 'a3-main',
        name: 'Main Portrait',
        captureOrder: 1,
        xPercent: 10,
        yPercent: 10,
        widthPercent: 80,
        heightPercent: 55,
        shape: 'rectangle',
        guideLabel: 'Main Pose',
      }),
      createLayoutSlot({
        id: 'a3-small-left',
        name: 'Small Left',
        captureOrder: 2,
        xPercent: 10,
        yPercent: 70,
        widthPercent: 37,
        heightPercent: 20,
        shape: 'rectangle',
        guideLabel: 'Small Pose 1',
      }),
      createLayoutSlot({
        id: 'a3-small-right',
        name: 'Small Right',
        captureOrder: 3,
        xPercent: 53,
        yPercent: 70,
        widthPercent: 37,
        heightPercent: 20,
        shape: 'rectangle',
        guideLabel: 'Small Pose 2',
      }),
    ],
    notes: 'Custom A3 poster layout sample.',
  }),
];

export const defaultActivePhotoLayout = defaultPhotoLayouts[0];
TS

cat > apps/booth-ui/src/layouts/index.ts <<'TS'
export * from './types';
export * from './layout-utils';
export * from './default-layouts';
TS

echo ""
echo "Created:"
echo "- apps/booth-ui/src/layouts/types.ts"
echo "- apps/booth-ui/src/layouts/layout-utils.ts"
echo "- apps/booth-ui/src/layouts/default-layouts.ts"
echo "- apps/booth-ui/src/layouts/index.ts"
echo ""
echo "Phase 10D1A completed."
