import type {
  PhotoLayout,
  PhotoLayoutSlot,
} from '../layouts';

export type CaptureGuideStep = {
  index: number;
  total: number;
  slot: PhotoLayoutSlot;
  label: string;
};

export function getCaptureOrderedSlots(
  layout: PhotoLayout,
): PhotoLayoutSlot[] {
  return [...layout.slots]
    .filter((slot) => slot.showGuide)
    .sort((a, b) => a.captureOrder - b.captureOrder);
}

export function getCaptureGuideStep(input: {
  layout: PhotoLayout;
  index: number;
}): CaptureGuideStep | null {
  const slots = getCaptureOrderedSlots(input.layout);

  if (slots.length === 0) {
    return null;
  }

  const safeIndex = Math.max(0, Math.min(input.index, slots.length - 1));
  const slot = slots[safeIndex];

  return {
    index: safeIndex,
    total: slots.length,
    slot,
    label: slot.guideLabel || slot.name || `Pose ${safeIndex + 1}`,
  };
}
