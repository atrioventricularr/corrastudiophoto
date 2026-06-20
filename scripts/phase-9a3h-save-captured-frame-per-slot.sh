#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3H - Save Captured Frame per Slot"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/CapturedFramesProvider.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/camera/CapturedFramesPanel.tsx <<'TSX'
import React from 'react';
import { useLayouts } from '../layouts';
import { useCapturedFrames } from './CapturedFramesProvider';

export function CapturedFramesPanel() {
  const { activeLayout } = useLayouts();
  const {
    capturedFramesBySlotId,
    removeCapturedFrame,
    clearCapturedFrames,
  } = useCapturedFrames();

  const capturedCount = Object.keys(capturedFramesBySlotId).length;

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Captured Frames
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {capturedCount} / {activeLayout.slots.length} Slots Captured
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Hasil capture sementara per slot layout aktif.
          </p>
        </div>

        <button
          type="button"
          onClick={clearCapturedFrames}
          disabled={capturedCount === 0}
          className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-black text-red-700 disabled:opacity-40"
        >
          Clear All
        </button>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {activeLayout.slots.map((slot) => {
          const frame = capturedFramesBySlotId[slot.id];

          return (
            <div
              key={slot.id}
              className="rounded-2xl border border-slate-100 bg-slate-50 p-3"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="text-sm font-black text-slate-800">
                    #{slot.captureOrder} · {slot.name}
                  </p>
                  <p className="mt-1 text-xs font-bold text-slate-500">
                    {frame ? 'Captured' : 'Waiting'}
                  </p>
                </div>

                {frame && (
                  <button
                    type="button"
                    onClick={() => removeCapturedFrame(slot.id)}
                    className="rounded-xl border border-red-200 bg-white px-3 py-2 text-[10px] font-black text-red-700"
                  >
                    Remove
                  </button>
                )}
              </div>

              {frame ? (
                <img
                  src={frame.dataUrl}
                  alt={slot.name}
                  className="mt-3 h-28 w-full rounded-xl border border-slate-200 bg-white object-cover"
                />
              ) : (
                <div className="mt-3 flex h-28 items-center justify-center rounded-xl border border-dashed border-slate-300 bg-white text-xs font-bold text-slate-400">
                  No photo yet
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
TSX

grep -q "CapturedFramesProvider" apps/booth-ui/src/camera/index.ts || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './CapturedFramesProvider';
export * from './CapturedFramesPanel';
TS

COUNTDOWN="apps/booth-ui/src/camera/CameraCountdownPanel.tsx"

[ -f "$COUNTDOWN" ] || {
  echo "ERROR: $COUNTDOWN not found. Run 9A3G first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraCountdownPanel.tsx")
text = path.read_text()

if "useCapturedFrames" not in text:
    text = text.replace(
        "import { useCameraCaptureGuide } from './CameraCaptureGuideProvider';",
        "import { useCameraCaptureGuide } from './CameraCaptureGuideProvider';\nimport { useCapturedFrames } from './CapturedFramesProvider';",
    )

if "saveCapturedFrame" not in text:
    text = text.replace(
        "  const { guideSettings } = useLayouts();",
        "  const { guideSettings } = useLayouts();\n  const { saveCapturedFrame } = useCapturedFrames();",
        1,
    )

old = """        setCapturedFrame(result);
        setStatus('captured');
        setLastMessage("""

new = """        setCapturedFrame(result);
        saveCapturedFrame({
          slotId: activeStep.slot.id,
          slotName: activeStep.slot.name,
          frame: result,
        });
        setStatus('captured');
        setLastMessage("""

if "slotId: activeStep.slot.id" not in text:
    if old not in text:
        raise SystemExit("Could not find setCapturedFrame block.")
    text = text.replace(old, new, 1)

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

if "CapturedFramesProvider" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { CapturedFramesPanel } from './CapturedFramesPanel';")
    lines.insert(insert_at, "import { CapturedFramesProvider } from './CapturedFramesProvider';")
    text = "\n".join(lines) + "\n"

# Wrap camera capture guide provider block with CapturedFramesProvider.
if "<CapturedFramesProvider>" not in text:
    pattern = re.compile(
        r"(<CameraCaptureGuideProvider>[\s\S]*?</CameraCaptureGuideProvider>)",
        re.MULTILINE,
    )
    match = pattern.search(text)

    if not match:
      raise SystemExit("Could not find CameraCaptureGuideProvider block.")

    block = match.group(1)
    wrapped = (
        "<CapturedFramesProvider>\n"
        f"      {block}\n"
        "      <CapturedFramesPanel />\n"
        "      </CapturedFramesProvider>"
    )

    text = text[:match.start(1)] + wrapped + text[match.end(1):]

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "CapturedFrames\\|saveCapturedFrame\\|capturedFramesBySlotId" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3H done."
