#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B3 - Booth Welcome Real CTA"
echo "========================================"

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/BoothWelcomeStep.tsx <<'TSX'
import React from 'react';
import { useBoothFlow } from './BoothFlowProvider';

export function BoothWelcomeStep() {
  const { session, setStep } = useBoothFlow();

  const handleStart = () => {
    setStep('payment');
  };

  return (
    <div className="mt-4 grid gap-6 lg:grid-cols-[1.2fr_0.8fr] lg:items-stretch">
      <div className="rounded-[2rem] bg-white p-6 text-slate-950">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-blue-500">
          Welcome to
        </p>

        <h4 className="mt-3 text-5xl font-black leading-none sm:text-6xl">
          Corra Booth
        </h4>

        <p className="mt-4 max-w-2xl text-base font-bold leading-relaxed text-slate-600">
          Ambil foto, pilih pose, dan dapatkan hasil final yang siap dicetak
          atau dibagikan. Ikuti instruksi di layar, booth akan memandu dari awal
          sampai selesai.
        </p>

        <div className="mt-6 grid gap-3 sm:grid-cols-3">
          <div className="rounded-3xl bg-blue-50 p-4">
            <p className="text-2xl font-black text-blue-700">01</p>
            <p className="mt-2 text-sm font-black text-slate-950">
              Guided Pose
            </p>
            <p className="mt-1 text-xs font-bold text-slate-500">
              Ikuti panduan pose di layar.
            </p>
          </div>

          <div className="rounded-3xl bg-emerald-50 p-4">
            <p className="text-2xl font-black text-emerald-700">02</p>
            <p className="mt-2 text-sm font-black text-slate-950">
              Auto Render
            </p>
            <p className="mt-1 text-xs font-bold text-slate-500">
              Foto otomatis masuk template.
            </p>
          </div>

          <div className="rounded-3xl bg-violet-50 p-4">
            <p className="text-2xl font-black text-violet-700">03</p>
            <p className="mt-2 text-sm font-black text-slate-950">
              Print Ready
            </p>
            <p className="mt-1 text-xs font-bold text-slate-500">
              Output siap cetak/delivery.
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={handleStart}
          className="mt-8 w-full rounded-3xl bg-slate-950 px-6 py-5 text-base font-black uppercase tracking-[0.18em] text-white shadow-lg shadow-black/20"
        >
          Start Photo Session
        </button>

        {session && (
          <p className="mt-3 text-center text-xs font-bold text-slate-400">
            Session already active. Continue to payment.
          </p>
        )}
      </div>

      <aside className="rounded-[2rem] border border-white/10 bg-white/10 p-6">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
          Session Package
        </p>

        <div className="mt-4 rounded-[2rem] bg-white p-5 text-slate-950">
          <p className="text-sm font-black uppercase tracking-[0.2em] text-slate-400">
            Photo Session
          </p>

          <div className="mt-3 flex items-end gap-2">
            <p className="text-4xl font-black">Rp50K</p>
            <p className="pb-1 text-sm font-black text-slate-400">
              / session
            </p>
          </div>

          <p className="mt-3 text-sm font-bold text-slate-500">
            Harga ini masih placeholder. Nanti akan disambungkan ke payment
            settings admin.
          </p>
        </div>

        <div className="mt-4 grid gap-3">
          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-sm font-black">Included</p>
            <p className="mt-1 text-xs font-semibold text-white/60">
              Multi-pose capture, template render, dan print/digital output.
            </p>
          </div>

          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-sm font-black">Next Step</p>
            <p className="mt-1 text-xs font-semibold text-white/60">
              Setelah start, customer diarahkan ke layar payment.
            </p>
          </div>
        </div>
      </aside>
    </div>
  );
}
TSX

grep -q "BoothWelcomeStep" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './BoothWelcomeStep';
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

if "BoothWelcomeStep" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { BoothWelcomeStep } from './BoothWelcomeStep';")
    text = "\n".join(lines) + "\n"

pattern = re.compile(
    r"""\{currentStep === 'welcome' && \(
            <div className="mt-4">
              <h4 className="text-4xl font-black">Welcome to Corra Booth</h4>
              <p className="mt-2 text-sm font-semibold text-white/70">
                Tap start untuk mulai sesi photobooth.
              </p>
            </div>
          \)\}""",
    re.MULTILINE,
)

replacement = """{currentStep === 'welcome' && <BoothWelcomeStep />}"""

if "<BoothWelcomeStep />" not in text:
    text2 = pattern.sub(replacement, text, count=1)

    if text2 == text:
        raise SystemExit("Could not replace welcome block. Please inspect BoothCustomerScreen.tsx manually.")

    text = text2

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "BoothWelcomeStep\\|Start Photo Session\\|Rp50K" -n apps/booth-ui/src/booth || true

echo ""
echo "9B3 done."
