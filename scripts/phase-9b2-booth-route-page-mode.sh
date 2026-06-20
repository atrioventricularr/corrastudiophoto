#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9B2 - Booth Route / Page Mode"
echo "========================================"

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/BoothModePage.tsx <<'TSX'
import React from 'react';
import { BoothCustomerScreen } from './BoothCustomerScreen';
import { BoothFlowProvider } from './BoothFlowProvider';

function goToAdminMode() {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.delete('mode');
  url.searchParams.delete('booth');
  url.hash = '';

  window.location.href = url.toString();
}

export function BoothModePage() {
  return (
    <main className="min-h-screen bg-slate-950 p-4 text-white sm:p-6 lg:p-8">
      <div className="mx-auto flex max-w-7xl flex-col gap-4">
        <header className="flex flex-col gap-3 rounded-[2rem] border border-white/10 bg-white/5 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.25em] text-white/40">
              Corra Booth
            </p>
            <h1 className="mt-1 text-2xl font-black">
              Customer Booth Mode
            </h1>
            <p className="mt-1 text-sm font-semibold text-white/50">
              Full-page customer-facing flow. Buka via <code>?mode=booth</code>{' '}
              atau <code>#/booth</code>.
            </p>
          </div>

          <button
            type="button"
            onClick={goToAdminMode}
            className="rounded-2xl bg-white px-4 py-3 text-xs font-black text-slate-950"
          >
            Back to Admin
          </button>
        </header>

        <BoothFlowProvider>
          <BoothCustomerScreen />
        </BoothFlowProvider>
      </div>
    </main>
  );
}
TSX

grep -q "BoothModePage" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './BoothModePage';
TS

cat > apps/booth-ui/src/AppModeRouter.tsx <<'TSX'
import React from 'react';
import App from './App';
import { BoothModePage } from './booth';

function isBoothModeUrl() {
  if (typeof window === 'undefined') return false;

  const url = new URL(window.location.href);
  const mode = url.searchParams.get('mode');
  const booth = url.searchParams.get('booth');
  const hash = window.location.hash.toLowerCase();
  const pathname = window.location.pathname.toLowerCase();

  return (
    mode === 'booth' ||
    booth === '1' ||
    hash === '#/booth' ||
    hash === '#booth' ||
    pathname.endsWith('/booth')
  );
}

export function AppModeRouter() {
  if (isBoothModeUrl()) {
    return <BoothModePage />;
  }

  return <App />;
}
TSX

MAIN="apps/booth-ui/src/main.tsx"

[ -f "$MAIN" ] || {
  echo "ERROR: $MAIN not found."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/main.tsx")
text = path.read_text()

if "AppModeRouter" not in text:
    # Replace normal App import.
    text2 = re.sub(
        r"import\s+App\s+from\s+['\"]\.\/App(?:\.tsx)?['\"]\s*;",
        "import { AppModeRouter } from './AppModeRouter';",
        text,
        count=1,
    )

    if text2 == text:
        # Fallback: add router import, leave App import alone.
        lines = text.splitlines()
        insert_at = 0

        for index, line in enumerate(lines):
            if line.startswith("import "):
                insert_at = index + 1

        lines.insert(insert_at, "import { AppModeRouter } from './AppModeRouter';")
        text2 = "\n".join(lines) + "\n"

    text = text2

# Replace JSX App with AppModeRouter.
text = re.sub(r"<App\s*/>", "<AppModeRouter />", text, count=1)

path.write_text(text)
print("PATCH:", path)
PY

PREVIEW="apps/booth-ui/src/booth/BoothFlowPreviewPanel.tsx"

[ -f "$PREVIEW" ] && python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/BoothFlowPreviewPanel.tsx")
text = path.read_text()

if "Open Booth Mode" not in text:
    text = text.replace(
        """        <p className="mt-1 text-sm font-semibold text-slate-500">
          Fondasi layar customer. Nanti flow ini dipisah dari admin hardware page
          dan dijadikan mode booth full-screen.
        </p>
      </div>""",
        """        <p className="mt-1 text-sm font-semibold text-slate-500">
          Fondasi layar customer. Nanti flow ini dipisah dari admin hardware page
          dan dijadikan mode booth full-screen.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <a
            href="?mode=booth"
            className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
          >
            Open Booth Mode
          </a>

          <a
            href="#/booth"
            className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700"
          >
            Open Hash Route
          </a>
        </div>
      </div>""",
        1,
    )

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -R "AppModeRouter\\|BoothModePage\\|mode=booth\\|Open Booth Mode" -n apps/booth-ui/src/main.tsx apps/booth-ui/src/AppModeRouter.tsx apps/booth-ui/src/booth || true

echo ""
echo "9B2 done."
