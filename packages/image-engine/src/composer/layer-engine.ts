import type { BoothLayout, BoothTemplate } from "@corra/shared";
import type { Capture } from "@corra/booth-core";
import {
  imageSourceFromPhotoAsset,
  imageSourceFromTemplate,
} from "../canvas/image-source";
import type { ImageSource } from "../canvas/canvas.types";

export type CompositionLayerKind = "TEMPLATE_BACKGROUND" | "RAW_CAPTURE";

export interface TemplateBackgroundLayer {
  kind: "TEMPLATE_BACKGROUND";
  order: 0;
  source: ImageSource;
}

export interface RawCaptureLayer {
  kind: "RAW_CAPTURE";
  order: number;
  slotIndex: number;
  capture: Capture;
  source: ImageSource;
}

export type CompositionLayer = TemplateBackgroundLayer | RawCaptureLayer;

export interface BuildCompositionLayersInput {
  layout: BoothLayout;
  template: BoothTemplate;
  captures: Capture[];
}

export function buildCompositionLayers(
  input: BuildCompositionLayersInput,
): CompositionLayer[] {
  const { layout, template, captures } = input;

  if (layout.id !== template.layoutId) {
    throw new Error("Template layout ID does not match selected layout ID.");
  }

  if (captures.length !== layout.slotCount) {
    throw new Error(
      `Layout requires ${layout.slotCount} captures, but received ${captures.length}.`,
    );
  }

  const layers: CompositionLayer[] = [
    {
      kind: "TEMPLATE_BACKGROUND",
      order: 0,
      source: imageSourceFromTemplate(template),
    },
  ];

  for (const capture of captures) {
    const slotExists = layout.slots.some(
      (slot) => slot.slotIndex === capture.slotIndex,
    );

    if (!slotExists) {
      throw new Error(`Capture slot ${capture.slotIndex} does not exist in layout.`);
    }

    layers.push({
      kind: "RAW_CAPTURE",
      order: 10 + capture.slotIndex,
      slotIndex: capture.slotIndex,
      capture,
      source: imageSourceFromPhotoAsset(capture.asset),
    });
  }

  return layers.sort((a, b) => a.order - b.order);
}
