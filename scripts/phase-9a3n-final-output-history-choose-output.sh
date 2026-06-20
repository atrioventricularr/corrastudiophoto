#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3N - Final Output History + Choose Output"
echo "========================================"

PROVIDER="apps/booth-ui/src/camera/CameraRenderOutputProvider.tsx"
PANEL="apps/booth-ui/src/camera/CameraRenderOutputPanel.tsx"

[ -f "$PROVIDER" ] || {
  echo "ERROR: $PROVIDER not found. Run 9A3M first."
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
  outputHistory: CameraRenderOutput[];
  saveRenderOutput: (input: SaveCameraRenderOutputInput) => CameraRenderOutput;
  selectRenderOutput: (outputId: string) => void;
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
  const [selectedOutputId, setSelectedOutputId] = useState('');

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

  const clearRenderOutputs = useCallback(() => {
    setOutputHistory([]);
    setSelectedOutputId('');
  }, []);

  const latestOutput = outputHistory[0] || null;

  const selectedOutput =
    outputHistory.find((output) => output.id === selectedOutputId) ||
    latestOutput;

  const value = useMemo<CameraRenderOutputContextValue>(() => {
    return {
      latestOutput,
      selectedOutput,
      selectedOutputId: selectedOutput?.id || '',
      outputHistory,
      saveRenderOutput,
      selectRenderOutput,
      clearRenderOutputs,
    };
  }, [
    latestOutput,
    selectedOutput,
    outputHistory,
    saveRenderOutput,
    selectRenderOutput,
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

cat > "$PANEL" <<'TSX'
import React from 'react';
import {
  type CameraRenderOutput,
  useCameraRenderOutput,
} from './CameraRenderOutputProvider';

function downloadOutput(output: CameraRenderOutput) {
  const safeTemplateName = output.templateName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  const link = document.createElement('a');
  link.href = output.dataUrl;
  link.download = `${safeTemplateName || 'corra'}-${output.renderMode}-session-output.png`;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

function formatRenderTime(value: string) {
  return new Intl.DateTimeFormat('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    day: '2-digit',
    month: 'short',
  }).format(new Date(value));
}

export function CameraRenderOutputPanel() {
  const {
    selectedOutput,
    selectedOutputId,
    outputHistory,
    selectRenderOutput,
    clearRenderOutputs,
  } = useCameraRenderOutput();

  if (!selectedOutput) {
    return (
      <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Session Final Output
        </p>
        <h4 className="mt-1 text-xl font-black text-slate-950">
          No Final Output Yet
        </h4>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Setelah render final berhasil, output akan masuk ke history session.
        </p>
      </section>
    );
  }

  return (
    <section className="rounded-3xl border border-emerald-200 bg-emerald-50 p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
            Session Final Output
          </p>
          <h4 className="mt-1 text-xl font-black text-emerald-950">
            Selected Render Output
          </h4>
          <p className="mt-1 text-sm font-semibold text-emerald-700">
            Pilih output dari history untuk dipakai/download.
          </p>
        </div>

        <span className="rounded-full bg-emerald-600 px-3 py-1 text-xs font-black text-white">
          {outputHistory.length} saved
        </span>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-4">
        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Size
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {selectedOutput.widthPx} × {selectedOutput.heightPx}px
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Mode
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {selectedOutput.renderMode}
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Source
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {selectedOutput.source}
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Captures
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {selectedOutput.capturedSlotCount} / {selectedOutput.totalSlotCount}
          </p>
        </div>
      </div>

      <div className="mt-4 rounded-3xl bg-white/80 p-4">
        <img
          src={selectedOutput.dataUrl}
          alt="Selected final output"
          className="mx-auto max-h-[420px] rounded-xl border border-emerald-100 bg-white object-contain"
        />
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <button
          type="button"
          onClick={() => downloadOutput(selectedOutput)}
          className="rounded-2xl bg-emerald-600 px-4 py-3 text-xs font-black text-white"
        >
          Download Selected Output
        </button>

        <button
          type="button"
          onClick={clearRenderOutputs}
          className="rounded-2xl border border-red-200 bg-white px-4 py-3 text-xs font-black text-red-700"
        >
          Clear Output History
        </button>
      </div>

      <div className="mt-4 rounded-3xl bg-white/70 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
          Output History
        </p>

        <div className="mt-3 grid gap-3">
          {outputHistory.map((output, index) => {
            const isSelected = output.id === selectedOutputId;

            return (
              <button
                key={output.id}
                type="button"
                onClick={() => selectRenderOutput(output.id)}
                className={`grid gap-3 rounded-2xl p-3 text-left sm:grid-cols-[96px_1fr_auto] sm:items-center ${
                  isSelected
                    ? 'bg-emerald-600 text-white'
                    : 'bg-white text-emerald-950'
                }`}
              >
                <img
                  src={output.dataUrl}
                  alt={`Render output ${index + 1}`}
                  className="h-20 w-24 rounded-xl border border-black/10 bg-white object-cover"
                />

                <div>
                  <p className="text-sm font-black">
                    {index === 0 ? 'Latest Output' : `Output ${index + 1}`}
                  </p>
                  <p
                    className={`mt-1 text-xs font-bold ${
                      isSelected ? 'text-white/80' : 'text-emerald-700'
                    }`}
                  >
                    {formatRenderTime(output.renderedAt)} · {output.renderMode} ·{' '}
                    {output.source}
                  </p>
                  <p
                    className={`mt-1 text-xs font-bold ${
                      isSelected ? 'text-white/70' : 'text-emerald-600'
                    }`}
                  >
                    {output.widthPx} × {output.heightPx}px ·{' '}
                    {output.capturedSlotCount}/{output.totalSlotCount} captures
                  </p>
                </div>

                <span
                  className={`rounded-full px-3 py-1 text-[10px] font-black ${
                    isSelected
                      ? 'bg-white text-emerald-700'
                      : 'bg-emerald-100 text-emerald-700'
                  }`}
                >
                  {isSelected ? 'Selected' : 'Choose'}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </section>
  );
}
TSX

echo ""
echo "Relevant lines:"
grep -R "selectedOutput\\|selectRenderOutput\\|Output History\\|Download Selected Output" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3N done."
