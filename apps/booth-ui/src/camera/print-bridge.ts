export type CameraPrintBridgeInput = {
  jobId: string;
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  copies: number;
  templateName: string;
  renderMode: string;
};

export type CameraPrintBridgeResult = {
  ok: boolean;
  jobId?: string;
  printerName?: string;
  message?: string;
  error?: string;
};

type CorraPrintBridge = {
  printImageDataUrl?: (
    input: CameraPrintBridgeInput,
  ) => Promise<CameraPrintBridgeResult>;
};

type CorraWindow = Window & {
  corra?: {
    print?: CorraPrintBridge;
  };
  corraPrintBridge?: CorraPrintBridge;
};

export function getCameraPrintBridge(): CorraPrintBridge | null {
  if (typeof window === 'undefined') return null;

  const maybeWindow = window as CorraWindow;

  return maybeWindow.corra?.print || maybeWindow.corraPrintBridge || null;
}

export function isCameraPrintBridgeAvailable(): boolean {
  return Boolean(getCameraPrintBridge()?.printImageDataUrl);
}

export async function printImageThroughBridge(
  input: CameraPrintBridgeInput,
): Promise<CameraPrintBridgeResult> {
  const bridge = getCameraPrintBridge();

  if (!bridge?.printImageDataUrl) {
    return {
      ok: false,
      jobId: input.jobId,
      error:
        'Electron print bridge is not available. Run inside Electron after the preload/main print handler is added.',
    };
  }

  try {
    return await bridge.printImageDataUrl(input);
  } catch (error) {
    return {
      ok: false,
      jobId: input.jobId,
      error:
        error instanceof Error
          ? error.message
          : 'Unknown print bridge error.',
    };
  }
}
