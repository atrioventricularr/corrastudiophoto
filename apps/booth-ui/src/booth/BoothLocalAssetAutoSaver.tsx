import { useEffect, useRef } from 'react';
import {
  useCameraRenderOutput,
  useCapturedFrames,
} from '../camera';
import { useBoothFlow } from './BoothFlowProvider';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';
import { useBoothLocalAssets } from './BoothLocalAssetProvider';

function isDataUrl(value: unknown): value is string {
  return typeof value === 'string' && value.startsWith('data:');
}

function getOutputDataUrl(output: unknown) {
  const value = output as {
    dataUrl?: unknown;
  };

  return isDataUrl(value.dataUrl) ? value.dataUrl : '';
}

function getOutputId(output: unknown) {
  const value = output as {
    id?: unknown;
  };

  return typeof value.id === 'string' ? value.id : '';
}

function getOutputNumber(output: unknown, key: string) {
  const value = output as Record<string, unknown>;
  const raw = value[key];

  return typeof raw === 'number' && Number.isFinite(raw) ? raw : undefined;
}

function getOutputString(output: unknown, key: string) {
  const value = output as Record<string, unknown>;
  const raw = value[key];

  return typeof raw === 'string' ? raw : undefined;
}

export function BoothLocalAssetAutoSaver() {
  const {
    session,
    currentStep,
    paymentStatus,
  } = useBoothFlow();

  const {
    photosBySlotId,
  } = useCapturedFrames();

  const {
    outputHistory,
  } = useCameraRenderOutput();

  const {
    saveAsset,
  } = useBoothLocalAssets();

  const {
    recordBoothEvent,
  } = useBoothLifecycleLogger();

  const savedRawKeysRef = useRef<Set<string>>(new Set());
  const savedOutputKeysRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    if (!session?.id) return;

    void (async () => {
      for (const [slotId, dataUrl] of Object.entries(photosBySlotId)) {
        if (!isDataUrl(dataUrl)) continue;

        const key = `${session.id}:raw:${slotId}:${dataUrl.length}`;

        if (savedRawKeysRef.current.has(key)) continue;

        savedRawKeysRef.current.add(key);

        const asset = await saveAsset({
          sessionId: session.id,
          kind: 'raw_capture',
          dataUrl,
          slotId,
          source: 'booth_auto_capture',
          metadata: {
            currentStep,
            paymentStatus,
          },
        });

        if (asset) {
          recordBoothEvent({
            type: 'debug_note',
            summary: `Raw capture saved locally for ${slotId}.`,
            sessionId: session.id,
            step: currentStep,
            paymentStatus,
            payload: {
              assetId: asset.id,
              slotId,
              filename: asset.filename,
              sizeBytes: asset.sizeBytes,
            },
          });
        }
      }
    })();
  }, [
    currentStep,
    paymentStatus,
    photosBySlotId,
    recordBoothEvent,
    saveAsset,
    session?.id,
  ]);

  useEffect(() => {
    if (!session?.id) return;

    void (async () => {
      for (const output of outputHistory) {
        const outputId = getOutputId(output);
        const dataUrl = getOutputDataUrl(output);

        if (!outputId || !dataUrl) continue;

        const key = `${session.id}:output:${outputId}`;

        if (savedOutputKeysRef.current.has(key)) continue;

        savedOutputKeysRef.current.add(key);

        const asset = await saveAsset({
          sessionId: session.id,
          kind: 'final_output',
          dataUrl,
          outputId,
          templateId: getOutputString(output, 'templateId'),
          templateName: getOutputString(output, 'templateName'),
          layoutId: getOutputString(output, 'layoutId'),
          layoutName: getOutputString(output, 'layoutName'),
          renderMode: getOutputString(output, 'renderMode'),
          widthPx: getOutputNumber(output, 'widthPx'),
          heightPx: getOutputNumber(output, 'heightPx'),
          source: 'booth_auto_render',
          metadata: {
            currentStep,
            paymentStatus,
            capturedSlotCount: getOutputNumber(output, 'capturedSlotCount'),
            totalSlotCount: getOutputNumber(output, 'totalSlotCount'),
          },
        });

        if (asset) {
          recordBoothEvent({
            type: 'debug_note',
            summary: 'Final output saved locally.',
            sessionId: session.id,
            step: currentStep,
            paymentStatus,
            payload: {
              assetId: asset.id,
              outputId,
              filename: asset.filename,
              sizeBytes: asset.sizeBytes,
            },
          });
        }
      }
    })();
  }, [
    currentStep,
    outputHistory,
    paymentStatus,
    recordBoothEvent,
    saveAsset,
    session?.id,
  ]);

  return null;
}
