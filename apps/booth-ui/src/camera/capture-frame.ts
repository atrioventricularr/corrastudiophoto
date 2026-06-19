export type CameraFrameCaptureResult = {
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  capturedAt: string;
};

export function getCameraPreviewVideoElement(): HTMLVideoElement | null {
  if (typeof document === 'undefined') return null;

  return document.querySelector<HTMLVideoElement>(
    '[data-corra-camera-preview-video="true"]',
  );
}

export function captureCameraPreviewFrame(input: {
  mirror?: boolean;
  mimeType?: 'image/png' | 'image/jpeg';
  quality?: number;
} = {}): CameraFrameCaptureResult {
  const video = getCameraPreviewVideoElement();

  if (!video) {
    throw new Error('Camera preview video element was not found.');
  }

  const width = video.videoWidth;
  const height = video.videoHeight;

  if (!width || !height) {
    throw new Error('Camera video is not ready yet.');
  }

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;

  const context = canvas.getContext('2d');

  if (!context) {
    throw new Error('Canvas 2D context is not available.');
  }

  if (input.mirror) {
    context.translate(width, 0);
    context.scale(-1, 1);
  }

  context.drawImage(video, 0, 0, width, height);

  return {
    dataUrl: canvas.toDataURL(input.mimeType || 'image/png', input.quality),
    widthPx: width,
    heightPx: height,
    capturedAt: new Date().toISOString(),
  };
}
