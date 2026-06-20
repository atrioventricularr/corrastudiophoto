#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3M - Save Final Output Local Session"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/CameraRenderOutputProvider.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/camera/CameraRenderOutputPanel.tsx <<'TSX'
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

export function CameraRenderOutputPanel() {
  const {
    latestOutput,
    outputHistory,
    clearRenderOutputs,
  } = useCameraRenderOutput();

  if (!latestOutput) {
    return (
      <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Session Final Output
        </p>
        <h4 className="mt-1 text-xl font-black text-slate-950">
          No Final Output Yet
        </h4>
        <p className="mt-1 text-sm font-semibold text-slate-500">
          Setelah render final berhasil, hasilnya akan tersimpan sementara di
          local session ini.
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
            Latest Render Saved
          </h4>
          <p className="mt-1 text-sm font-semibold text-emerald-700">
            Output terakhir sudah tersimpan di local session sementara.
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
            {latestOutput.widthPx} × {latestOutput.heightPx}px
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Mode
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {latestOutput.renderMode}
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Source
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {latestOutput.source}
          </p>
        </div>

        <div className="rounded-2xl bg-white/80 p-3">
          <p className="text-[10px] font-black uppercase text-emerald-500">
            Captures
          </p>
          <p className="mt-1 text-sm font-black text-emerald-950">
            {latestOutput.capturedSlotCount} / {latestOutput.totalSlotCount}
          </p>
        </div>
      </div>

      <div className="mt-4 rounded-3xl bg-white/80 p-4">
        <img
          src={latestOutput.dataUrl}
          alt="Latest final output"
          className="mx-auto max-h-[420px] rounded-xl border border-emerald-100 bg-white object-contain"
        />
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <button
          type="button"
          onClick={() => downloadOutput(latestOutput)}
          className="rounded-2xl bg-emerald-600 px-4 py-3 text-xs font-black text-white"
        >
          Download Latest Output
        </button>

        <button
          type="button"
          onClick={clearRenderOutputs}
          className="rounded-2xl border border-red-200 bg-white px-4 py-3 text-xs font-black text-red-700"
        >
          Clear Session Outputs
        </button>
      </div>
    </section>
  );
}
TSX

grep -q "CameraRenderOutputProvider" apps/booth-ui/src/camera/index.ts || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './CameraRenderOutputProvider';
export * from './CameraRenderOutputPanel';
TS

RENDER_PANEL="apps/booth-ui/src/camera/CameraCapturedRenderPanel.tsx"

[ -f "$RENDER_PANEL" ] || {
  echo "ERROR: $RENDER_PANEL not found. Run 9A3I/9A3L first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraCapturedRenderPanel.tsx")
text = path.read_text()

if "useCameraRenderOutput" not in text:
    text = text.replace(
        "import { useCapturedFrames } from './CapturedFramesProvider';",
        "import { useCapturedFrames } from './CapturedFramesProvider';\nimport { useCameraRenderOutput } from './CameraRenderOutputProvider';",
    )

if "saveRenderOutput" not in text:
    text = text.replace(
        "  const { photosBySlotId, capturedFramesBySlotId } = useCapturedFrames();",
        "  const { photosBySlotId, capturedFramesBySlotId } = useCapturedFrames();\n  const { saveRenderOutput } = useCameraRenderOutput();",
        1,
    )

marker = """      if (source === 'auto') {
        setLastAutoRenderKey(renderKey);
      }"""

insertion = """      saveRenderOutput({
        dataUrl: result.dataUrl,
        widthPx: result.widthPx,
        heightPx: result.heightPx,
        renderMode,
        templateId: activeTemplate.id,
        templateName: activeTemplate.name,
        layoutId: renderLayout.id,
        layoutName: renderLayout.name,
        mirrorFinalOutput: guideSettings.mirrorFinalOutput,
        capturedSlotCount: capturedCount,
        totalSlotCount: renderLayout.slots.length,
        source,
      });

      if (source === 'auto') {
        setLastAutoRenderKey(renderKey);
      }"""

if "saveRenderOutput({" not in text:
    if marker not in text:
        raise SystemExit("Could not find auto render marker.")
    text = text.replace(marker, insertion, 1)

path.write_text(text)
print("PATCH:", path)
PY

SETUP="apps/booth-ui/src/camera/CameraSetupPanel.tsx"

[ -f "$SETUP" ] || {
  echo "ERROR: $SETUP not found."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/camera/CameraSetupPanel.tsx")
text = path.read_text()

if "CameraRenderOutputProvider" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { CameraRenderOutputPanel } from './CameraRenderOutputPanel';")
    lines.insert(insert_at, "import { CameraRenderOutputProvider } from './CameraRenderOutputProvider';")
    text = "\n".join(lines) + "\n"

if "<CameraRenderOutputProvider>" not in text:
    pattern = re.compile(
        r"(<CapturedFramesProvider>\s*)([\s\S]*?)(\s*</CapturedFramesProvider>)",
        re.MULTILINE,
    )
    match = pattern.search(text)

    if not match:
        raise SystemExit("Could not find CapturedFramesProvider block.")

    text = (
        text[:match.start()]
        + match.group(1)
        + "\n      <CameraRenderOutputProvider>"
        + match.group(2)
        + "\n      </CameraRenderOutputProvider>"
        + match.group(3)
        + text[match.end():]
    )

if "<CameraRenderOutputPanel />" not in text:
    marker = "<CameraCapturedRenderPanel />"

    if marker not in text:
        raise SystemExit(
            "Could not find <CameraCapturedRenderPanel />. Put <CameraRenderOutputPanel /> below it manually."
        )

    text = text.replace(
        marker,
        marker + "\n      <CameraRenderOutputPanel />",
        1,
    )

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "CameraRenderOutput\\|saveRenderOutput\\|Session Final Output" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3M done."
