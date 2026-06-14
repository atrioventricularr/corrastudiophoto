import type { LayoutSlot } from "@corra/shared";
import type { DrawImageOptions } from "../canvas/canvas.types";

export interface SlotTransformInput {
  slot: LayoutSlot;
}

export function slotToDrawImageOptions(
  input: SlotTransformInput,
): DrawImageOptions {
  const { slot } = input;

  if (slot.width <= 0 || slot.height <= 0) {
    throw new Error(`Invalid slot size for slot ${slot.slotIndex}.`);
  }

  return {
    x: slot.x,
    y: slot.y,
    width: slot.width,
    height: slot.height,
    rotationDeg: slot.rotationDeg,
    borderRadius: slot.borderRadius,
    objectFit: slot.objectFit,
  };
}
