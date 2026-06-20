#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3K - Capture Completion Status"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/capture-completion.ts <<'TS'
import type { PhotoLayout, PhotoLayoutSlot } from '../layouts';
import type { CapturedSlotFrame } from './CapturedFramesProvider';
import { getCaptureOrderedSlots } from './capture-guide';

export type CaptureCompletionStatus = {
  requiredSlots: PhotoLayoutSlot[];
  capturedSlots: PhotoLayoutSlot[];
  missingSlots: PhotoLayoutSlot[];
  totalRequired: number;
  totalCaptured: number;
  progressPercent: number;
  isComplete: boolean;
};

export function getCaptureCompletionStatus(input: {
  layout: PhotoLayout;
  capturedFramesBySlotId: Record<string, CapturedSlotFrame>;
}): CaptureCompletionStatus {
  const requiredSlots = getCaptureOrderedSlots(input.layout);

  const capturedSlots = requiredSlots.filter(
    (slot) => Boolean(input.capturedFramesBySlotId[slot.id]),
  );

  const missingSlots = requiredSlots.filter(
    (slot) => !input.capturedFramesBySlotId[slot.id],
  );

  const totalRequired = requiredSlots.length;
  const totalCaptured = capturedSlots.length;

  const progressPercent =
    totalRequired === 0
      ? 0
      : Math.round((totalCaptured / totalRequired) * 100);

  return {
    requiredSlots,
    capturedSlots,
    missingSlots,
    totalRequired,
    totalCaptured,
    progressPercent,
    isComplete: totalRequired > 0 && totalCaptured >= totalRequired,
  };
}
TS

cat > apps/booth-ui/src/camera/CameraCaptureCompletionPanel.tsx <<'TSX'
import React, { useMemo } from 'react';
import { useLayouts } from '../layouts';
import { getCaptureCompletionStatus } from './capture-completion';
import { useCameraCaptureGuide } from './CameraCaptureGuideProvider';
import { useCapturedFrames } from './CapturedFramesProvider';

export function CameraCaptureCompletionPanel() {
  const { activeLayout } = useLayouts();
  const { setActiveIndex, resetStep } = useCameraCaptureGuide();
  const {
    capturedFramesBySlotId,
    clearCapturedFrames,
  } = useCapturedFrames();

  const completion = useMemo(
    () =>
      getCaptureCompletionStatus({
        layout: activeLayout,
        capturedFramesBySlotId,
      }),
    [activeLayout, capturedFramesBySlotId],
  );

  const handleGoToFirstMissing = () => {
    if (completion.missingSlots.length === 0) return;

    const firstMissingSlot = completion.missingSlots[0];
    const missingIndex = completion.requiredSlots.findIndex(
      (slot) => slot.id === firstMissingSlot.id,
    );

    setActiveIndex(Math.max(0, missingIndex));
  };

  const handleResetCaptureFlow = () => {
    clearCapturedFrames();
    resetStep();
  };

  return (
    <section
      className={`rounded-3xl border p-4 shadow-sm ${
        completion.isComplete
          ? 'border-emerald-200 bg-emerald-50'
          : 'border-slate-200 bg-white'
      }`}
    >
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p
            className={`text-xs font-black uppercase tracking-[0.2em] ${
              completion.isComplete ? 'text-emerald-500' : 'text-slate-400'
            }`}
          >
            Capture Completion
          </p>
          <h4
            className={`mt-1 text-xl font-black ${
              completion.isComplete ? 'text-emerald-950' : 'text-slate-950'
            }`}
          >
            {completion.isComplete
              ? 'All Poses Complete'
              : `${completion.missingSlots.length} Pose Left`}
          </h4>
          <p
            className={`mt-1 text-sm font-semibold ${
              completion.isComplete ? 'text-emerald-700' : 'text-slate-500'
            }`}
          >
            {completion.totalCaptured} dari {completion.totalRequired} slot guide
            sudah captured.
          </p>
        </div>

        <span
          className={`rounded-full px-3 py-1 text-xs font-black ${
            completion.isComplete
              ? 'bg-emerald-600 text-white'
              : 'bg-slate-950 text-white'
          }`}
        >
          {completion.progressPercent}%
        </span>
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-white/80">
        <div
          className={`h-full rounded-full ${
            completion.isComplete ? 'bg-emerald-600' : 'bg-blue-600'
          }`}
          style={{ width: `${completion.progressPercent}%` }}
        />
      </div>

      <div className="mt-4 grid gap-2">
        {completion.requiredSlots.map((slot, index) => {
          const isCaptured = Boolean(capturedFramesBySlotId[slot.id]);

          return (
            <button
              key={slot.id}
              type="button"
              onClick={() => setActiveIndex(index)}
              className={`flex items-center justify-between rounded-2xl px-4 py-3 text-left text-xs font-black ${
                isCaptured
                  ? 'bg-emerald-100 text-emerald-800'
                  : 'bg-slate-50 text-slate-600'
              }`}
            >
              <span>
                {index + 1}. {slot.guideLabel || slot.name}
              </span>
              <span>{isCaptured ? 'Captured' : 'Missing'}</span>
            </button>
          );
        })}
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <button
          type="button"
          onClick={handleGoToFirstMissing}
          disabled={completion.isComplete || completion.missingSlots.length === 0}
          className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-xs font-black text-slate-700 disabled:opacity-40"
        >
          Go to First Missing
        </button>

        <button
          type="button"
          onClick={handleResetCaptureFlow}
          className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-black text-red-700"
        >
          Reset Capture Flow
        </button>
      </div>

      {completion.isComplete && (
        <div className="mt-4 rounded-2xl bg-white/80 p-3 text-sm font-bold text-emerald-800">
          Semua slot guide sudah punya foto. Sekarang bisa render final template
          di panel Captured Template Render.
        </div>
      )}
    </section>
  );
}
TSX

grep -q "capture-completion" apps/booth-ui/src/camera/index.ts || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './capture-completion';
export * from './CameraCaptureCompletionPanel';
TS

FILE="apps/booth-ui/src/camera/CameraSetupPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraSetupPanel.tsx")
text = path.read_text()

if "CameraCaptureCompletionPanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { CameraCaptureCompletionPanel } from './CameraCaptureCompletionPanel';",
    )
    text = "\n".join(lines) + "\n"

if "<CameraCaptureCompletionPanel />" not in text:
    marker = "<CapturedFramesPanel />"

    if marker not in text:
        raise SystemExit(
            "Could not find <CapturedFramesPanel />. Put <CameraCaptureCompletionPanel /> below it manually."
        )

    text = text.replace(
        marker,
        marker + "\n      <CameraCaptureCompletionPanel />",
        1,
    )

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "CameraCaptureCompletionPanel\\|getCaptureCompletionStatus\\|All Poses Complete" -n apps/booth-ui/src/camera || true

echo ""
echo "9A3K done."
