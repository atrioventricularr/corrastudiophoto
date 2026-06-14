import type { PhotoAsset } from "@corra/shared";
import type { PrinterPort } from "../ports/printer.port";

export interface PrintFrameInput {
  frameAsset: PhotoAsset;
  copies: number;
}

export async function printFrameUseCase(
  printer: PrinterPort,
  input: PrintFrameInput,
) {
  if (input.frameAsset.kind !== "FINAL_FRAME") {
    throw new Error("Only FINAL_FRAME assets can be printed.");
  }

  if (!Number.isInteger(input.copies) || input.copies <= 0) {
    throw new Error("Print copies must be a positive integer.");
  }

  return printer.printFrame({
    frameAsset: input.frameAsset,
    copies: input.copies,
  });
}
