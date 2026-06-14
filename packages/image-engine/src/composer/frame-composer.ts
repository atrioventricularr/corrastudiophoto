import type { PhotoAsset } from "@corra/shared";
import type { ComposeFrameRequest, ImageComposerPort } from "@corra/booth-core";
import type { CanvasAdapter } from "../canvas/canvas.types";
import { buildCompositionLayers } from "./layer-engine";
import { slotToDrawImageOptions } from "./slot-transform";

export interface FrameComposerOptions {
  outputMimeType?: "image/png" | "image/jpeg" | "image/webp";
  outputQuality?: number;
}

export class FrameComposer implements ImageComposerPort {
  constructor(
    private readonly canvasAdapter: CanvasAdapter,
    private readonly options: FrameComposerOptions = {},
  ) {}

  async composeFrame(request: ComposeFrameRequest): Promise<PhotoAsset> {
    const { sessionId, frameId, layout, template, captures } = request;

    if (layout.canvasWidth !== template.canvasWidth) {
      throw new Error("Layout width and template width must match.");
    }

    if (layout.canvasHeight !== template.canvasHeight) {
      throw new Error("Layout height and template height must match.");
    }

    const canvas = await this.canvasAdapter.createCanvas(
      layout.canvasWidth,
      layout.canvasHeight,
    );

    const layers = buildCompositionLayers({
      layout,
      template,
      captures,
    });

    for (const layer of layers) {
      if (layer.kind === "TEMPLATE_BACKGROUND") {
        const image = await this.canvasAdapter.loadImage(layer.source);

        await this.canvasAdapter.drawImage(canvas, image, {
          x: 0,
          y: 0,
          width: layout.canvasWidth,
          height: layout.canvasHeight,
          rotationDeg: 0,
          borderRadius: 0,
          objectFit: "cover",
        });

        continue;
      }

      const slot = layout.slots.find(
        (layoutSlot) => layoutSlot.slotIndex === layer.slotIndex,
      );

      if (!slot) {
        throw new Error(`Slot not found: ${layer.slotIndex}.`);
      }

      const image = await this.canvasAdapter.loadImage(layer.source);

      await this.canvasAdapter.drawImage(
        canvas,
        image,
        slotToDrawImageOptions({ slot }),
      );
    }

    return this.canvasAdapter.exportCanvas(canvas, {
      sessionId,
      frameId,
      mimeType: this.options.outputMimeType ?? "image/png",
      quality: this.options.outputQuality,
    });
  }
}
