import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import type { SlotPhotoMap } from '../render';
import type { CameraFrameCaptureResult } from './capture-frame';

export type CapturedSlotFrame = CameraFrameCaptureResult & {
  slotId: string;
  slotName: string;
};

type CapturedFramesContextValue = {
  capturedFramesBySlotId: Record<string, CapturedSlotFrame>;
  photosBySlotId: SlotPhotoMap;
  saveCapturedFrame: (input: {
    slotId: string;
    slotName: string;
    frame: CameraFrameCaptureResult;
  }) => void;
  removeCapturedFrame: (slotId: string) => void;
  clearCapturedFrames: () => void;
};

const CapturedFramesContext =
  createContext<CapturedFramesContextValue | null>(null);

type CapturedFramesProviderProps = {
  children: ReactNode;
};

export function CapturedFramesProvider({
  children,
}: CapturedFramesProviderProps) {
  const [capturedFramesBySlotId, setCapturedFramesBySlotId] =
    useState<Record<string, CapturedSlotFrame>>({});

  const saveCapturedFrame = useCallback(
    (input: {
      slotId: string;
      slotName: string;
      frame: CameraFrameCaptureResult;
    }) => {
      setCapturedFramesBySlotId((current) => ({
        ...current,
        [input.slotId]: {
          ...input.frame,
          slotId: input.slotId,
          slotName: input.slotName,
        },
      }));
    },
    [],
  );

  const removeCapturedFrame = useCallback((slotId: string) => {
    setCapturedFramesBySlotId((current) => {
      const next = { ...current };
      delete next[slotId];
      return next;
    });
  }, []);

  const clearCapturedFrames = useCallback(() => {
    setCapturedFramesBySlotId({});
  }, []);

  const photosBySlotId = useMemo<SlotPhotoMap>(() => {
    return Object.fromEntries(
      Object.entries(capturedFramesBySlotId).map(([slotId, frame]) => [
        slotId,
        frame.dataUrl,
      ]),
    );
  }, [capturedFramesBySlotId]);

  const value = useMemo<CapturedFramesContextValue>(() => {
    return {
      capturedFramesBySlotId,
      photosBySlotId,
      saveCapturedFrame,
      removeCapturedFrame,
      clearCapturedFrames,
    };
  }, [
    capturedFramesBySlotId,
    photosBySlotId,
    saveCapturedFrame,
    removeCapturedFrame,
    clearCapturedFrames,
  ]);

  return (
    <CapturedFramesContext.Provider value={value}>
      {children}
    </CapturedFramesContext.Provider>
  );
}

export function useCapturedFrames(): CapturedFramesContextValue {
  const context = useContext(CapturedFramesContext);

  if (!context) {
    throw new Error(
      'useCapturedFrames must be used inside CapturedFramesProvider',
    );
  }

  return context;
}
