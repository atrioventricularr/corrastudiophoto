#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: TemplateRenderPreviewPanel.tsx not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateRenderPreviewPanel.tsx")
text = path.read_text()

old = """  const renderLayout =
    layouts.find((item) => item.id === activeTemplate.layoutId) ||
    activeLayout;"""

new = """  const renderLayout =
    layouts.find((item) => item.id === activeTemplate.layoutId) ||
    activeLayout;

  const samplePhotoCount = Object.keys(samplePhotosBySlotId).length;"""

if "samplePhotoCount" not in text:
    if old not in text:
        raise SystemExit("Could not find renderLayout block.")
    text = text.replace(old, new, 1)

old = """  const handleRemoveSamplePhoto = (slotId: string) => {
    setSamplePhotosBySlotId((current) => {
      const next = { ...current };
      delete next[slotId];
      return next;
    });
  };

  return ("""

new = """  const handleRemoveSamplePhoto = (slotId: string) => {
    setSamplePhotosBySlotId((current) => {
      const next = { ...current };
      delete next[slotId];
      return next;
    });
  };

  const handleClearSamplePhotos = () => {
    setSamplePhotosBySlotId({});
  };

  return ("""

if "handleClearSamplePhotos" not in text:
    if old not in text:
        raise SystemExit("Could not find handleRemoveSamplePhoto block.")
    text = text.replace(old, new, 1)

marker = """      <div className="mt-4 rounded-2xl border border-emerald-100 bg-emerald-50 p-4">"""

status_block = """      <div className="mt-4 rounded-2xl border border-cyan-100 bg-cyan-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-cyan-500">
          Render Status
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-4">
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Mode
            </p>
            <p className="mt-1 text-sm font-black text-cyan-950">
              {renderMode === 'print-ready' ? 'Print-Ready' : 'Raw Template'}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Sample Photos
            </p>
            <p className="mt-1 text-sm font-black text-cyan-950">
              {samplePhotoCount} / {renderLayout.slots.length}
            </p>
          </div>

          <div className="rounded-2xl bg-white p-3">
            <p className="text-[10px] font-black uppercase text-cyan-400">
              Template
            </p>
            <p className="mt-1 truncate text-sm font-black text-cyan-950">
              {activeTemplate.name}
            </p>
          </div>

          <button
            type="button"
            onClick={handleClearSamplePhotos}
            disabled={samplePhotoCount === 0}
            className="rounded-2xl border border-cyan-200 bg-white px-4 py-3 text-xs font-black text-cyan-700 disabled:opacity-40"
          >
            Clear Sample Photos
          </button>
        </div>
      </div>

"""

if "Render Status" not in text:
    if marker not in text:
        raise SystemExit("Could not find Sample Photos block marker.")
    text = text.replace(marker, status_block + marker, 1)

path.write_text(text)
print("10D2G patched:", path)
PY

echo "10D2G mini done."
