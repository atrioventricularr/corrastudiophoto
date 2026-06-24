#!/usr/bin/env bash
set -euo pipefail

cat > apps/booth-ui/src/booth/BoothKioskAdminUnlock.tsx <<'TSX'
import React, { useEffect, useState } from 'react';
import { buildBoothModeHref, goToAdminMode } from './booth-mode-utils';

type BoothKioskAdminUnlockProps = {
  enabled: boolean;
};

export function BoothKioskAdminUnlock({
  enabled,
}: BoothKioskAdminUnlockProps) {
  const [tapCount, setTapCount] = useState(0);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (tapCount <= 0) return;

    const timer = window.setTimeout(() => {
      setTapCount(0);
    }, 2500);

    return () => window.clearTimeout(timer);
  }, [tapCount]);

  if (!enabled) return null;

  const handleSecretTap = () => {
    setTapCount((current) => {
      const next = current + 1;

      if (next >= 5) {
        setVisible(true);
        return 0;
      }

      return next;
    });
  };

  return (
    <>
      <button
        type="button"
        aria-label="Hidden kiosk unlock"
        onClick={handleSecretTap}
        className="fixed bottom-0 left-0 z-50 h-24 w-24 opacity-0"
      />

      {tapCount > 0 && !visible && (
        <div className="fixed bottom-5 left-5 z-50 rounded-full bg-black/70 px-3 py-2 text-xs font-black text-white backdrop-blur">
          {tapCount}/5
        </div>
      )}

      {visible && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-5 backdrop-blur">
          <section className="w-full max-w-lg rounded-[2rem] bg-white p-6 text-slate-950">
            <p className="text-xs font-black uppercase tracking-[0.25em] text-blue-500">
              Kiosk Unlock
            </p>

            <h3 className="mt-3 text-4xl font-black">
              Admin Access
            </h3>

            <p className="mt-3 text-sm font-bold leading-relaxed text-slate-600">
              Panel ini muncul setelah hidden corner kiri bawah ditekan 5 kali.
              Gunakan hanya untuk operator/admin.
            </p>

            <div className="mt-6 grid gap-3">
              <a
                href={buildBoothModeHref({
                  dev: true,
                  kiosk: false,
                })}
                className="rounded-3xl bg-slate-950 px-5 py-4 text-center text-xs font-black uppercase tracking-[0.15em] text-white"
              >
                Open Booth Dev Mode
              </a>

              <button
                type="button"
                onClick={goToAdminMode}
                className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
              >
                Back to Admin
              </button>

              <button
                type="button"
                onClick={() => setVisible(false)}
                className="rounded-3xl border border-slate-200 bg-slate-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
              >
                Close
              </button>
            </div>
          </section>
        </div>
      )}
    </>
  );
}
TSX

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/BoothModePage.tsx")
text = path.read_text()

if "BoothKioskAdminUnlock" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { BoothKioskAdminUnlock } from './BoothKioskAdminUnlock';",
    )
    text = "\n".join(lines) + "\n"

if "<BoothKioskAdminUnlock" not in text:
    marker = """      </div>
    </main>
  );"""

    replacement = """      </div>

      <BoothKioskAdminUnlock enabled={isKioskMode && !isDevMode} />
    </main>
  );"""

    if marker not in text:
        raise SystemExit("Could not find BoothModePage closing marker.")

    text = text.replace(marker, replacement, 1)

path.write_text(text)
print("PATCH:", path)
PY

grep -q "BoothKioskAdminUnlock" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './BoothKioskAdminUnlock';
TS

echo "Hidden admin unlock added."
