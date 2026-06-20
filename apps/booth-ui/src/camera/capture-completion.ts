import type { PhotoLayout, PhotoLayoutSlot } from '../layouts';
import type { CapturedSlotFrame } from './CapturedFramesProvider';
import { getCaptureOrderedSlots } from './capture-guide';

export type CaptureCompletionStatus = {
  requiredSlots: PhotoLayoutSlot[];
  capturedSlots: PhotoLayoutSlot[];
  missingSlots: PhotoLayoutSlot[];
  totalRequired: number;
  totalCaptured: number;
  progressPercent: number;
  isComplete: boolean;
};

export function getCaptureCompletionStatus(input: {
  layout: PhotoLayout;
  capturedFramesBySlotId: Record<string, CapturedSlotFrame>;
}): CaptureCompletionStatus {
  const requiredSlots = getCaptureOrderedSlots(input.layout);

  const capturedSlots = requiredSlots.filter(
    (slot) => Boolean(input.capturedFramesBySlotId[slot.id]),
  );

  const missingSlots = requiredSlots.filter(
    (slot) => !input.capturedFramesBySlotId[slot.id],
  );

  const totalRequired = requiredSlots.length;
  const totalCaptured = capturedSlots.length;

  const progressPercent =
    totalRequired === 0
      ? 0
      : Math.round((totalCaptured / totalRequired) * 100);

  return {
    requiredSlots,
    capturedSlots,
    missingSlots,
    totalRequired,
    totalCaptured,
    progressPercent,
    isComplete: totalRequired > 0 && totalCaptured >= totalRequired,
  };
}
