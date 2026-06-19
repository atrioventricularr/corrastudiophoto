#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3E - Highlight Active Capture Slot"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/CameraCaptureGuideProvider.tsx <<'TSX'
import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { useLayouts } from '../layouts';
import {
  getCaptureGuideStep,
  getCaptureOrderedSlots,
  type CaptureGuideStep,
} from './capture-guide';

type CameraCaptureGuideContextValue = {
  activeIndex: number;
  activeStep: CaptureGuideStep | null;
  total: number;
  setActiveIndex: (index: number) => void;
  previousStep: () => void;
  nextStep: () => void;
  resetStep: () => void;
};

const CameraCaptureGuideContext =
  createContext<CameraCaptureGuideContextValue | null>(null);

type CameraCaptureGuideProviderProps = {
  children: ReactNode;
};

export function CameraCaptureGuideProvider({
  children,
}: CameraCaptureGuideProviderProps) {
  const { activeLayout } = useLayouts();
  const [activeIndex, setActiveIndexState] = useState(0);

  const orderedSlots = useMemo(
    () => getCaptureOrderedSlots(activeLayout),
    [activeLayout],
  );

  const activeStep = getCaptureGuideStep({
    layout: activeLayout,
    index: activeIndex,
  });

  useEffect(() => {
    if (activeIndex > orderedSlots.length - 1) {
      setActiveIndexState(Math.max(0, orderedSlots.length - 1));
    }
  }, [activeIndex, orderedSlots.length]);

  const setActiveIndex = (index: number) => {
    setActiveIndexState(
      Math.max(0, Math.min(index, Math.max(0, orderedSlots.length - 1))),
    );
  };

  const previousStep = () => {
    setActiveIndex(activeIndex - 1);
  };

  const nextStep = () => {
    setActiveIndex(activeIndex + 1);
  };

  const resetStep = () => {
    setActiveIndex(0);
  };

  return (
    <CameraCaptureGuideContext.Provider
      value={{
        activeIndex,
        activeStep,
        total: orderedSlots.length,
        setActiveIndex,
        previousStep,
        nextStep,
        resetStep,
      }}
    >
      {children}
    </CameraCaptureGuideContext.Provider>
  );
}

export function useCameraCaptureGuide(): CameraCaptureGuideContextValue {
  const context = useContext(CameraCaptureGuideContext);

  if (!context) {
    throw new Error(
      'useCameraCaptureGuide must be used inside CameraCaptureGuideProvider',
    );
  }

  return context;
}

export function useOptionalCameraCaptureGuide():
  | CameraCaptureGuideContextValue
  | null {
  return useContext(CameraCaptureGuideContext);
}
TSX

cat > apps/booth-ui/src/camera/CameraCaptureGuidePanel.tsx <<'TSX'
import React, { useMemo } from 'react';
import { useLayouts } from '../layouts';
import { getCaptureOrderedSlots } from './capture-guide';
import { useCameraCaptureGuide } from './CameraCaptureGuideProvider';

export function CameraCaptureGuidePanel() {
  const { activeLayout } = useLayouts();
  const {
    activeIndex,
    activeStep,
    setActiveIndex,
    previousStep,
    nextStep,
    resetStep,
  } = useCameraCaptureGuide();

  const orderedSlots = useMemo(
    () => getCaptureOrderedSlots(activeLayout),
    [activeLayout],
  );

  if (!activeStep) {
    return (
      <section className="rounded-3xl border border-amber-200 bg-amber-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-amber-500">
          Capture Guide
        </p>
        <p className="mt-2 text-sm font-bold text-amber-800">
          Belum ada slot guide aktif di layout ini.
        </p>
      </section>
    );
  }

  const isFirst = activeStep.index === 0;
  const isLast = activeStep.index === activeStep.total - 1;

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Capture Guide
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {activeStep.label}
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Slot {activeStep.index + 1} dari {activeStep.total} ·{' '}
            {activeStep.slot.name}
          </p>
        </div>

        <span className="rounded-full bg-blue-600 px-3 py-1 text-xs font-black text-white">
          Active #{activeStep.slot.captureOrder}
        </span>
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-slate-100">
        <div
          className="h-full rounded-full bg-blue-600"
          style={{
            width: `${((activeStep.index + 1) / activeStep.total) * 100}%`,
          }}
        />
      </div>

      <div className="mt-4 grid gap-2 sm:grid-cols-3">
        <button
          type="button"
          onClick={previousStep}
          disabled={isFirst}
          className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700 disabled:opacity-40"
        >
          Previous Pose
        </button>

        <button
          type="button"
          onClick={resetStep}
          className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-xs font-black text-slate-700"
        >
          Reset
        </button>

        <button
          type="button"
          onClick={nextStep}
          disabled={isLast}
          className="rounded-2xl bg-blue-600 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
        >
          Next Pose
        </button>
      </div>

      <div className="mt-4 grid gap-2">
        {orderedSlots.map((slot, index) => (
          <button
            key={slot.id}
            type="button"
            onClick={() => setActiveIndex(index)}
            className={`rounded-2xl px-4 py-3 text-left text-xs font-black ${
              index === activeIndex
                ? 'bg-blue-600 text-white'
                : 'bg-slate-50 text-slate-600'
            }`}
          >
            {index + 1}. {slot.guideLabel || slot.name}
          </button>
        ))}
      </div>
    </section>
  );
}
TSX

cat > apps/booth-ui/src/camera/CameraGuideOverlay.tsx <<'TSX'
import React from 'react';
import { useLayouts } from '../layouts';
import { useOptionalCameraCaptureGuide } from './CameraCaptureGuideProvider';

export function CameraGuideOverlay() {
  const {
    activeLayout,
    guideSettings,
  } = useLayouts();

  const captureGuide = useOptionalCameraCaptureGuide();
  const activeSlotId = captureGuide?.activeStep?.slot.id;
  const opacity = guideSettings.guideOpacity;

  if (!guideSettings.showGrid && !guideSettings.showSlotGuide) {
    return null;
  }

  return (
    <div
      className="pointer-events-none absolute inset-0 z-20 overflow-hidden rounded-[inherit]"
      style={{
        opacity,
      }}
    >
      {guideSettings.showGrid && (
        <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.35)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.35)_1px,transparent_1px)] bg-[size:10%_10%]" />
      )}

      {guideSettings.showSlotGuide &&
        activeLayout.slots
          .filter((slot) => slot.showGuide)
          .map((slot) => {
            const isActive = slot.id === activeSlotId;

            return (
              <div
                key={slot.id}
                className={`absolute flex items-center justify-center border-2 border-dashed text-center shadow-[0_0_0_1px_rgba(0,0,0,0.25)] ${
                  isActive
                    ? 'border-yellow-300 bg-yellow-300/25 ring-4 ring-yellow-300/70'
                    : 'border-white bg-black/15'
                }`}
                style={{
                  left: `${slot.xPercent}%`,
                  top: `${slot.yPercent}%`,
                  width: `${slot.widthPercent}%`,
                  height: `${slot.heightPercent}%`,
                  borderRadius:
                    slot.shape === 'circle'
                      ? '9999px'
                      : `${slot.borderRadiusPercent}%`,
                  transform: `rotate(${slot.rotationDeg}deg)`,
                }}
              >
                <div
                  className={`rounded-full px-3 py-1 ${
                    isActive ? 'bg-yellow-300 text-black' : 'bg-black/55 text-white'
                  }`}
                >
                  <p className="text-[10px] font-black uppercase tracking-wider">
                    {slot.guideLabel || slot.name}
                  </p>
                  <p className="mt-0.5 font-mono text-[9px] font-bold opacity-75">
                    #{slot.captureOrder}
                  </p>
                </div>
              </div>
            );
          })}
    </div>
  );
}
TSX

grep -q "CameraCaptureGuideProvider" apps/booth-ui/src/camera/index.ts || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './CameraCaptureGuideProvider';
TS

FILE="apps/booth-ui/src/camera/CameraSetupPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/camera/CameraSetupPanel.tsx")
text = path.read_text()

if "CameraCaptureGuideProvider" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { CameraCaptureGuideProvider } from './CameraCaptureGuideProvider';",
    )
    text = "\n".join(lines) + "\n"

if "<CameraCaptureGuideProvider>" not in text:
    pattern = re.compile(
        r"(<CameraLivePreview[\s\S]*?\/>\s*\n\s*<CameraCaptureGuidePanel\s*\/>)",
        re.MULTILINE,
    )
    match = pattern.search(text)

    if match:
        block = match.group(1)
        wrapped = (
            "<CameraCaptureGuideProvider>\n"
            f"      {block}\n"
            "      </CameraCaptureGuideProvider>"
        )
        text = text[:match.start(1)] + wrapped + text[match.end(1):]
    else:
        raise SystemExit(
            "Could not find CameraLivePreview + CameraCaptureGuidePanel block. Wrap them manually with <CameraCaptureGuideProvider>."
        )

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "CameraCaptureGuideProvider\\|useCameraCaptureGuide\\|activeSlotId\\|ring-yellow" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3E done."
