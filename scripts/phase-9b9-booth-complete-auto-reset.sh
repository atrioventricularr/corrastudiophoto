#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B9 - Booth Complete Auto Reset"
echo "========================================"

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/BoothCompleteStep.tsx <<'TSX'
import React, {
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  useCameraCaptureGuide,
  useCameraPrintQueue,
  useCameraRenderOutput,
  useCapturedFrames,
} from '../camera';
import { useBoothFlow } from './BoothFlowProvider';

export function BoothCompleteStep() {
  const {
    session,
    setStep,
    resetSession,
  } = useBoothFlow();

  const { resetStep } = useCameraCaptureGuide();

  const {
    capturedFramesBySlotId,
    clearCapturedFrames,
  } = useCapturedFrames();

  const {
    selectedOutput,
    outputHistory,
    clearRenderOutputs,
  } = useCameraRenderOutput();

  const {
    printJobs,
    clearPrintJobs,
  } = useCameraPrintQueue();

  const [secondsLeft, setSecondsLeft] = useState(8);
  const [autoResetEnabled, setAutoResetEnabled] = useState(true);
  const [resetDone, setResetDone] = useState(false);

  const completedPrintJobs = useMemo(
    () => printJobs.filter((job) => job.status === 'completed'),
    [printJobs],
  );

  const failedPrintJobs = useMemo(
    () => printJobs.filter((job) => job.status === 'failed'),
    [printJobs],
  );

  const capturedCount = Object.keys(capturedFramesBySlotId).length;

  const resetBoothSession = () => {
    clearCapturedFrames();
    clearRenderOutputs();
    clearPrintJobs();
    resetStep();
    resetSession();
    setResetDone(true);
  };

  useEffect(() => {
    if (!autoResetEnabled || resetDone) return;

    if (secondsLeft <= 0) {
      resetBoothSession();
      return;
    }

    const timer = window.setTimeout(() => {
      setSecondsLeft((current) => current - 1);
    }, 1000);

    return () => window.clearTimeout(timer);
  }, [autoResetEnabled, resetDone, secondsLeft]);

  if (resetDone) {
    return (
      <div className="mt-4 rounded-[2rem] bg-white p-8 text-center text-slate-950">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-emerald-500">
          Reset Complete
        </p>
        <h4 className="mt-3 text-5xl font-black leading-none">
          Ready for Next Customer
        </h4>
        <p className="mx-auto mt-4 max-w-xl text-sm font-bold text-slate-600">
          Local session sudah dibersihkan. Booth akan kembali ke welcome screen.
        </p>
      </div>
    );
  }

  return (
    <div className="mt-4 grid gap-6 xl:grid-cols-[1fr_0.9fr]">
      <section className="rounded-[2rem] bg-white p-8 text-center text-slate-950">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-emerald-500">
          Session Complete
        </p>

        <h4 className="mt-4 text-6xl font-black leading-none sm:text-7xl">
          Thank You!
        </h4>

        <p className="mx-auto mt-5 max-w-2xl text-base font-bold leading-relaxed text-slate-600">
          Terima kasih sudah menggunakan Corra Booth. Silakan ambil hasil print
          atau file digital kamu.
        </p>

        <div className="mx-auto mt-8 flex h-44 w-44 items-center justify-center rounded-full bg-slate-950 text-white">
          <div>
            <p className="text-6xl font-black">{secondsLeft}</p>
            <p className="mt-1 text-xs font-black uppercase tracking-[0.2em] text-white/50">
              reset
            </p>
          </div>
        </div>

        <p className="mt-5 text-sm font-bold text-slate-500">
          Booth akan otomatis reset untuk customer berikutnya.
        </p>

        <div className="mt-8 grid gap-3 sm:grid-cols-3">
          <button
            type="button"
            onClick={() => setStep('delivery')}
            className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            Back to Delivery
          </button>

          <button
            type="button"
            onClick={() => setAutoResetEnabled((current) => !current)}
            className="rounded-3xl border border-slate-200 bg-slate-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            {autoResetEnabled ? 'Pause Auto Reset' : 'Resume Auto Reset'}
          </button>

          <button
            type="button"
            onClick={resetBoothSession}
            className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
          >
            Reset Now
          </button>
        </div>
      </section>

      <aside className="rounded-[2rem] border border-white/10 bg-white/10 p-6">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
          Session Summary
        </p>

        <div className="mt-5 grid gap-3">
          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-xs font-black uppercase text-white/40">
              Session ID
            </p>
            <p className="mt-2 break-all font-mono text-xs font-bold text-white/70">
              {session?.id || 'No session'}
            </p>
          </div>

          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-xs font-black uppercase text-white/40">
              Captured Frames
            </p>
            <p className="mt-2 text-3xl font-black text-white">
              {capturedCount}
            </p>
          </div>

          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-xs font-black uppercase text-white/40">
              Render Outputs
            </p>
            <p className="mt-2 text-3xl font-black text-white">
              {outputHistory.length}
            </p>
            <p className="mt-1 text-xs font-bold text-white/50">
              {selectedOutput ? 'Final output selected' : 'No selected output'}
            </p>
          </div>

          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-xs font-black uppercase text-white/40">
              Print Jobs
            </p>
            <p className="mt-2 text-3xl font-black text-white">
              {printJobs.length}
            </p>
            <p className="mt-1 text-xs font-bold text-white/50">
              {completedPrintJobs.length} completed · {failedPrintJobs.length} failed
            </p>
          </div>
        </div>

        <div className="mt-5 rounded-3xl bg-black/20 p-4">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Reset Action
          </p>
          <p className="mt-2 text-sm font-semibold text-white/60">
            Auto reset akan menghapus local captured frames, render output,
            print queue, dan mengembalikan pose ke awal. Data admin settings
            tidak akan ikut terhapus.
          </p>
        </div>
      </aside>
    </div>
  );
}
TSX

grep -q "BoothCompleteStep" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './BoothCompleteStep';
TS

SCREEN="apps/booth-ui/src/booth/BoothCustomerScreen.tsx"

[ -f "$SCREEN" ] || {
  echo "ERROR: $SCREEN not found. Run 9B1 first."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/booth/BoothCustomerScreen.tsx")
text = path.read_text()

if "BoothCompleteStep" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { BoothCompleteStep } from './BoothCompleteStep';")
    text = "\n".join(lines) + "\n"

if "<BoothCompleteStep />" not in text:
    pattern = re.compile(
        r"""\{currentStep === 'complete' && \(
            <div className="mt-4">
              <h4 className="text-4xl font-black">Thank You!</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Session selesai\. Booth siap reset ke welcome screen\.
              </p>
            </div>
          \)\}""",
        re.MULTILINE,
    )

    text2 = pattern.sub("{currentStep === 'complete' && <BoothCompleteStep />}", text, count=1)

    if text2 == text:
        raise SystemExit("Could not replace complete block. Inspect BoothCustomerScreen.tsx manually.")

    text = text2

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "BoothCompleteStep\\|Thank You\\|Reset Now\\|Ready for Next Customer" -n apps/booth-ui/src/booth || true

echo ""
echo "9B9 done."
