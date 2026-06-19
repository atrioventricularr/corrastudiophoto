#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10C1A - Paper Size Preset Foundation"
echo "========================================"

mkdir -p apps/booth-ui/src/print

cat > apps/booth-ui/src/print/paper-presets.ts <<'TS'
import type { PrintOrientation } from './types';

export type PaperPresetId =
  | '2r'
  | '4r'
  | '5r'
  | 'a5'
  | 'a4'
  | 'a3'
  | 'square'
  | 'custom';

export type PaperSizePreset = {
  id: PaperPresetId;
  name: string;
  widthInch: number;
  heightInch: number;
  recommendedDpi: number;
  category: 'photo' | 'document' | 'poster' | 'custom';
};

export type CanvasPixelSize = {
  widthPx: number;
  heightPx: number;
};

export const paperSizePresets: PaperSizePreset[] = [
  {
    id: '2r',
    name: '2R / 2.5x3.5 inch',
    widthInch: 2.5,
    heightInch: 3.5,
    recommendedDpi: 300,
    category: 'photo',
  },
  {
    id: '4r',
    name: '4R / 4x6 inch',
    widthInch: 4,
    heightInch: 6,
    recommendedDpi: 300,
    category: 'photo',
  },
  {
    id: '5r',
    name: '5R / 5x7 inch',
    widthInch: 5,
    heightInch: 7,
    recommendedDpi: 300,
    category: 'photo',
  },
  {
    id: 'a5',
    name: 'A5',
    widthInch: 5.83,
    heightInch: 8.27,
    recommendedDpi: 300,
    category: 'document',
  },
  {
    id: 'a4',
    name: 'A4',
    widthInch: 8.27,
    heightInch: 11.69,
    recommendedDpi: 300,
    category: 'document',
  },
  {
    id: 'a3',
    name: 'A3',
    widthInch: 11.69,
    heightInch: 16.54,
    recommendedDpi: 300,
    category: 'poster',
  },
  {
    id: 'square',
    name: 'Square / 6x6 inch',
    widthInch: 6,
    heightInch: 6,
    recommendedDpi: 300,
    category: 'photo',
  },
  {
    id: 'custom',
    name: 'Custom Size',
    widthInch: 4,
    heightInch: 6,
    recommendedDpi: 300,
    category: 'custom',
  },
];

export function findPaperPreset(id: PaperPresetId): PaperSizePreset {
  return (
    paperSizePresets.find((preset) => preset.id === id) ||
    paperSizePresets.find((preset) => preset.id === '4r') ||
    paperSizePresets[0]
  );
}

export function calculateCanvasPixelSize(input: {
  widthInch: number;
  heightInch: number;
  dpi: number;
  orientation: PrintOrientation;
}): CanvasPixelSize {
  const width =
    input.orientation === 'landscape' ? input.heightInch : input.widthInch;

  const height =
    input.orientation === 'landscape' ? input.widthInch : input.heightInch;

  return {
    widthPx: Math.round(width * input.dpi),
    heightPx: Math.round(height * input.dpi),
  };
}

export function getPaperPresetCanvasSize(input: {
  presetId: PaperPresetId;
  dpi?: number;
  orientation: PrintOrientation;
}): CanvasPixelSize {
  const preset = findPaperPreset(input.presetId);
  const dpi = input.dpi || preset.recommendedDpi;

  return calculateCanvasPixelSize({
    widthInch: preset.widthInch,
    heightInch: preset.heightInch,
    dpi,
    orientation: input.orientation,
  });
}
TS

grep -q "paper-presets" apps/booth-ui/src/print/index.ts || cat >> apps/booth-ui/src/print/index.ts <<'TS'
export * from './paper-presets';
TS

echo ""
echo "Created:"
echo "- apps/booth-ui/src/print/paper-presets.ts"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/print/index.ts"
echo ""
echo "Phase 10C1A completed."
