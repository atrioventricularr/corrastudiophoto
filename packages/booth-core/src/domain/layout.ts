import {
  assertValidBoothLayout,
  type BoothLayout,
  type LayoutSlot,
} from "@corra/shared";

export function createBoothLayout(layout: BoothLayout): BoothLayout {
  assertValidBoothLayout(layout);
  return layout;
}

export function getLayoutSlot(layout: BoothLayout, slotIndex: number): LayoutSlot {
  const slot = layout.slots.find((item) => item.slotIndex === slotIndex);

  if (!slot) {
    throw new Error(`Layout slot not found: ${slotIndex}.`);
  }

  return slot;
}
