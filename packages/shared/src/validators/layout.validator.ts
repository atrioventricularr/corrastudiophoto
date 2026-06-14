import {
  MAX_CAPTURE_PER_FRAME,
  MIN_CAPTURE_PER_FRAME,
} from "../constants/booth.constants";
import type { BoothLayout } from "../types/layout.types";

export function validateBoothLayout(layout: BoothLayout): string[] {
  const errors: string[] = [];

  if (!layout.id) errors.push("Layout ID is required.");
  if (!layout.name) errors.push("Layout name is required.");

  if (layout.canvasWidth <= 0) {
    errors.push("Canvas width must be greater than zero.");
  }

  if (layout.canvasHeight <= 0) {
    errors.push("Canvas height must be greater than zero.");
  }

  if (
    layout.slotCount < MIN_CAPTURE_PER_FRAME ||
    layout.slotCount > MAX_CAPTURE_PER_FRAME
  ) {
    errors.push(
      `Layout slot count must be between ${MIN_CAPTURE_PER_FRAME} and ${MAX_CAPTURE_PER_FRAME}.`,
    );
  }

  if (layout.slots.length !== layout.slotCount) {
    errors.push("Slot count does not match slots length.");
  }

  const seenIndexes = new Set<number>();

  for (const slot of layout.slots) {
    if (seenIndexes.has(slot.slotIndex)) {
      errors.push(`Duplicate slot index: ${slot.slotIndex}.`);
    }

    seenIndexes.add(slot.slotIndex);

    if (slot.width <= 0 || slot.height <= 0) {
      errors.push(`Slot ${slot.slotIndex} must have positive size.`);
    }

    if (slot.x < 0 || slot.y < 0) {
      errors.push(`Slot ${slot.slotIndex} cannot have negative position.`);
    }
  }

  return errors;
}

export function assertValidBoothLayout(layout: BoothLayout): void {
  const errors = validateBoothLayout(layout);

  if (errors.length > 0) {
    throw new Error(`Invalid booth layout: ${errors.join(" ")}`);
  }
}
