import type { CorraId, ISODateTimeString } from "./common.types";

export type LayoutSlotCount = 2 | 3 | 4 | 5 | 6 | 7 | 8;

export type SlotObjectFit = "cover" | "contain";

export interface LayoutSlot {
  slotIndex: number;
  x: number;
  y: number;
  width: number;
  height: number;
  rotationDeg: number;
  borderRadius: number;
  objectFit: SlotObjectFit;
}

export interface BoothLayout {
  id: CorraId;
  name: string;
  canvasWidth: number;
  canvasHeight: number;
  slotCount: LayoutSlotCount;
  slots: LayoutSlot[];
  isActive: boolean;
  createdAt: ISODateTimeString;
  updatedAt: ISODateTimeString;
}
