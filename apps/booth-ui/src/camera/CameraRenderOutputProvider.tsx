import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';

export type CameraRenderOutput = {
  id: string;
  dataUrl: string;
  widthPx: number;
  heightPx: number;
  renderMode: string;
  renderedAt: string;
  templateId: string;
  templateName: string;
  layoutId: string;
  layoutName: string;
  mirrorFinalOutput: boolean;
  capturedSlotCount: number;
  totalSlotCount: number;
  source: 'manual' | 'auto';
};

type SaveCameraRenderOutputInput = Omit<
  CameraRenderOutput,
  'id' | 'renderedAt'
>;

type CameraRenderOutputContextValue = {
  latestOutput: CameraRenderOutput | null;
  outputHistory: CameraRenderOutput[];
  saveRenderOutput: (input: SaveCameraRenderOutputInput) => CameraRenderOutput;
  clearRenderOutputs: () => void;
};

const CameraRenderOutputContext =
  createContext<CameraRenderOutputContextValue | null>(null);

type CameraRenderOutputProviderProps = {
  children: ReactNode;
};

export function CameraRenderOutputProvider({
  children,
}: CameraRenderOutputProviderProps) {
  const [outputHistory, setOutputHistory] = useState<CameraRenderOutput[]>([]);

  const saveRenderOutput = useCallback(
    (input: SaveCameraRenderOutputInput): CameraRenderOutput => {
      const output: CameraRenderOutput = {
        ...input,
        id: `render-${Date.now()}-${Math.random().toString(16).slice(2)}`,
        renderedAt: new Date().toISOString(),
      };

      setOutputHistory((current) => [output, ...current].slice(0, 10));

      return output;
    },
    [],
  );

  const clearRenderOutputs = useCallback(() => {
    setOutputHistory([]);
  }, []);

  const latestOutput = outputHistory[0] || null;

  const value = useMemo<CameraRenderOutputContextValue>(() => {
    return {
      latestOutput,
      outputHistory,
      saveRenderOutput,
      clearRenderOutputs,
    };
  }, [
    latestOutput,
    outputHistory,
    saveRenderOutput,
    clearRenderOutputs,
  ]);

  return (
    <CameraRenderOutputContext.Provider value={value}>
      {children}
    </CameraRenderOutputContext.Provider>
  );
}

export function useCameraRenderOutput(): CameraRenderOutputContextValue {
  const context = useContext(CameraRenderOutputContext);

  if (!context) {
    throw new Error(
      'useCameraRenderOutput must be used inside CameraRenderOutputProvider',
    );
  }

  return context;
}
