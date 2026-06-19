import {
  defaultPhotoLayouts,
  type PhotoLayout,
} from '../layouts';
import {
  createPhotoTemplate,
} from './template-utils';
import type {
  PhotoTemplate,
  TemplatePaperSnapshot,
} from './types';

export function createPaperSnapshotFromLayout(
  layout: PhotoLayout,
): TemplatePaperSnapshot {
  return {
    paperPresetId: layout.paperPresetId,
    paperName: layout.paperName,
    paperWidthInch: layout.paperWidthInch,
    paperHeightInch: layout.paperHeightInch,
    orientation: layout.orientation,
    dpi: layout.dpi,
    canvasWidthPx: layout.canvasWidthPx,
    canvasHeightPx: layout.canvasHeightPx,
  };
}

export const defaultPhotoTemplates: PhotoTemplate[] = defaultPhotoLayouts.map(
  (layout) =>
    createPhotoTemplate({
      name: `${layout.name} Basic Template`,
      customerFacingName: layout.name,
      layoutId: layout.id,
      layoutName: layout.name,
      paperSnapshot: createPaperSnapshotFromLayout(layout),
      tags: ['default', layout.paperPresetId, layout.mode],
      notes:
        'Default template without frame overlay. Add frame PNG later from Template Manager.',
    }),
);

export const defaultActivePhotoTemplate =
  defaultPhotoTemplates[0];
