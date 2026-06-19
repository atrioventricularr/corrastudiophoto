#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1D - Layout Guide Settings Editor"
echo "========================================"

FILE="apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: LayoutAdminPanel.tsx not found. Run 10D1C first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/LayoutAdminPanel.tsx")
text = path.read_text()

# Add updateGuideSettings to destructuring.
old = """    guideSettings,
    setActiveLayoutId,"""

new = """    guideSettings,
    setActiveLayoutId,
    updateGuideSettings,"""

if old in text and "updateGuideSettings" not in text.split("} = useLayouts();", 1)[0]:
    text = text.replace(old, new, 1)

marker = """      <div className="mt-5 overflow-hidden rounded-3xl border border-slate-100">"""

editor = """      <div className="mt-5 rounded-3xl border border-emerald-100 bg-emerald-50 p-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
              Guide Controls
            </p>
            <h4 className="mt-1 text-xl font-black text-emerald-950">
              Camera Preview Guide
            </h4>
            <p className="mt-1 text-xs font-bold text-emerald-700">
              Setting ini nanti dipakai di camera preview: mirror, grid, dan slot guide.
            </p>
          </div>

          <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-emerald-700">
            Opacity {Math.round(guideSettings.guideOpacity * 100)}%
          </span>
        </div>

        <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.showGrid}
              onChange={(event) =>
                updateGuideSettings({
                  showGrid: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Show grid
            </span>
          </label>

          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.showSlotGuide}
              onChange={(event) =>
                updateGuideSettings({
                  showSlotGuide: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Show slot guide
            </span>
          </label>

          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.mirrorPreview}
              onChange={(event) =>
                updateGuideSettings({
                  mirrorPreview: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Mirror preview
            </span>
          </label>

          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={guideSettings.mirrorFinalOutput}
              onChange={(event) =>
                updateGuideSettings({
                  mirrorFinalOutput: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Mirror final output
            </span>
          </label>
        </div>

        <label className="mt-4 block rounded-2xl bg-white px-4 py-3">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Guide Opacity
          </span>
          <input
            type="range"
            min="0"
            max="1"
            step="0.05"
            value={guideSettings.guideOpacity}
            onChange={(event) =>
              updateGuideSettings({
                guideOpacity: Number(event.target.value),
              })
            }
            className="mt-3 w-full"
          />
        </label>
      </div>

"""

if "Guide Controls" not in text:
    if marker not in text:
        raise SystemExit("Could not find Photo Slots table marker.")
    text = text.replace(marker, editor + marker, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Verifying..."

grep -q "Guide Controls" "$FILE" || {
  echo "ERROR: Guide Controls block missing."
  exit 1
}

grep -q "updateGuideSettings" "$FILE" || {
  echo "ERROR: updateGuideSettings missing."
  exit 1
}

echo ""
echo "Relevant lines:"
grep -n "Guide Controls\\|updateGuideSettings\\|Mirror preview\\|Mirror final output\\|Guide Opacity" "$FILE" || true

echo ""
echo "Phase 10D1D completed."
