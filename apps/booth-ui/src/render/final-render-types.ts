import type { PhotoLayout } from '../layouts';
import type { PhotoTemplate } from '../templates';

export type SlotPhotoMap = Record<string, string>;

export type FinalRenderOptions = {
  template: PhotoTemplate;
  layout: PhotoLayout;
  photosBySlotId?: SlotPhotoMap;
  showEmptySlotPlaceholder?: boolean;
  backgroundColor?: string;
  showCalibrationGuide?: boolean;
};

export type FinalRenderResult = {
  canvas: HTMLCanvasElement;
  dataUrl: string;
  widthPx: number;
  heightPx: number;
};
