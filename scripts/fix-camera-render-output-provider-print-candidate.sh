#!/usr/bin/env bash
set -euo pipefail

PROVIDER="apps/booth-ui/src/camera/CameraRenderOutputProvider.tsx"

[ -f "$PROVIDER" ] || {
  echo "ERROR: $PROVIDER not found."
  exit 1
}

cat > "$PROVIDER" <<'TSX'
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
  selectedOutput: CameraRenderOutput | null;
  selectedOutputId: string;
  printCandidateOutput: CameraRenderOutput | null;
  printCandidateOutputId: string;
  outputHistory: CameraRenderOutput[];
  saveRenderOutput: (input: SaveCameraRenderOutputInput) => CameraRenderOutput;
  selectRenderOutput: (outputId: string) => void;
  markOutputAsPrintCandidate: (outputId: string) => void;
  markSelectedOutputAsPrintCandidate: () => void;
  clearPrintCandidate: () => void;
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
  const [selectedOutputIdState, setSelectedOutputId] = useState('');
  const [printCandidateOutputIdState, setPrintCandidateOutputId] = useState('');

  const saveRenderOutput = useCallback(
    (input: SaveCameraRenderOutputInput): CameraRenderOutput => {
      const output: CameraRenderOutput = {
        ...input,
        id: `render-${Date.now()}-${Math.random().toString(16).slice(2)}`,
        renderedAt: new Date().toISOString(),
      };

      setOutputHistory((current) => [output, ...current].slice(0, 10));
      setSelectedOutputId(output.id);

      return output;
    },
    [],
  );

  const selectRenderOutput = useCallback((outputId: string) => {
    setSelectedOutputId(outputId);
  }, []);

  const markOutputAsPrintCandidate = useCallback((outputId: string) => {
    setPrintCandidateOutputId(outputId);
  }, []);

  const clearPrintCandidate = useCallback(() => {
    setPrintCandidateOutputId('');
  }, []);

  const clearRenderOutputs = useCallback(() => {
    setOutputHistory([]);
    setSelectedOutputId('');
    setPrintCandidateOutputId('');
  }, []);

  const latestOutput = outputHistory[0] || null;

  const selectedOutput =
    outputHistory.find((output) => output.id === selectedOutputIdState) ||
    latestOutput;

  const selectedOutputId = selectedOutput?.id || '';

  const printCandidateOutput =
    outputHistory.find((output) => output.id === printCandidateOutputIdState) ||
    null;

  const printCandidateOutputId = printCandidateOutput?.id || '';

  const markSelectedOutputAsPrintCandidate = useCallback(() => {
    if (!selectedOutputId) return;
    setPrintCandidateOutputId(selectedOutputId);
  }, [selectedOutputId]);

  const value = useMemo<CameraRenderOutputContextValue>(() => {
    return {
      latestOutput,
      selectedOutput,
      selectedOutputId,
      printCandidateOutput,
      printCandidateOutputId,
      outputHistory,
      saveRenderOutput,
      selectRenderOutput,
      markOutputAsPrintCandidate,
      markSelectedOutputAsPrintCandidate,
      clearPrintCandidate,
      clearRenderOutputs,
    };
  }, [
    latestOutput,
    selectedOutput,
    selectedOutputId,
    printCandidateOutput,
    printCandidateOutputId,
    outputHistory,
    saveRenderOutput,
    selectRenderOutput,
    markOutputAsPrintCandidate,
    markSelectedOutputAsPrintCandidate,
    clearPrintCandidate,
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
TSX

echo "Fixed CameraRenderOutputProvider print candidate context."
