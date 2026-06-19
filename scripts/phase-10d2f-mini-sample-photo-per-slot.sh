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

text = text.replace(
    "import { renderFinalTemplateToCanvas, renderPrintReadyTemplateToCanvas } from '../../render';",
    "import { renderFinalTemplateToCanvas, renderPrintReadyTemplateToCanvas, type SlotPhotoMap } from '../../render';",
)

old_state = """  const [isRendering, setIsRendering] = useState(false);
  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');"""

new_state = """  const [isRendering, setIsRendering] = useState(false);
  const [renderMode, setRenderMode] = useState<RenderMode>('print-ready');
  const [samplePhotosBySlotId, setSamplePhotosBySlotId] =
    useState<SlotPhotoMap>({});

  const renderLayout =
    layouts.find((item) => item.id === activeTemplate.layoutId) ||
    activeLayout;"""

if "samplePhotosBySlotId" not in text:
    text = text.replace(old_state, new_state, 1)

old_layout = """      const layout =
        layouts.find((item) => item.id === activeTemplate.layoutId) ||
        activeLayout;"""

if old_layout in text:
    text = text.replace(old_layout, "      const layout = renderLayout;", 1)

text = text.replace(
    "              showEmptySlotPlaceholder: true,",
    "              photosBySlotId: samplePhotosBySlotId,\n              showEmptySlotPlaceholder: true,",
    1,
)

text = text.replace(
    "              showEmptySlotPlaceholder: true,",
    "              photosBySlotId: samplePhotosBySlotId,\n              showEmptySlotPlaceholder: true,",
    1,
)

marker = """  const handleDownloadPreview = () => {
    if (!previewUrl) return;

    const safeName = activeTemplate.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const link = document.createElement('a');
    link.href = previewUrl;
    link.download = `${safeName || 'corra-template'}-render-preview.png`;
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  return ("""

handlers = """  const handleDownloadPreview = () => {
    if (!previewUrl) return;

    const safeName = activeTemplate.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const link = document.createElement('a');
    link.href = previewUrl;
    link.download = `${safeName || 'corra-template'}-render-preview.png`;
    document.body.appendChild(link);
    link.click();
    link.remove();
  };

  const handleSamplePhotoUpload = (
    slotId: string,
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (!file.type.startsWith('image/')) {
      window.alert('Sample photo harus image.');
      event.target.value = '';
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result !== 'string') return;

      setSamplePhotosBySlotId((current) => ({
        ...current,
        [slotId]: reader.result as string,
      }));
    };

    reader.readAsDataURL(file);
    event.target.value = '';
  };

  const handleRemoveSamplePhoto = (slotId: string) => {
    setSamplePhotosBySlotId((current) => {
      const next = { ...current };
      delete next[slotId];
      return next;
    });
  };

  return ("""

if "handleSamplePhotoUpload" not in text:
    text = text.replace(marker, handlers, 1)

insert_before = """      <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Render Mode
        </p>"""

sample_block = """      <div className="mt-4 rounded-2xl border border-emerald-100 bg-emerald-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-emerald-500">
          Sample Photos
        </p>
        <p className="mt-1 text-xs font-bold text-emerald-700">
          Upload foto dummy per slot untuk tes hasil render final.
        </p>

        <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {renderLayout.slots.map((slot) => (
            <div key={slot.id} className="rounded-2xl bg-white p-3">
              <p className="text-sm font-black text-slate-800">
                #{slot.captureOrder} · {slot.name}
              </p>

              {samplePhotosBySlotId[slot.id] && (
                <img
                  src={samplePhotosBySlotId[slot.id]}
                  alt={slot.name}
                  className="mt-3 h-24 w-full rounded-xl object-cover"
                />
              )}

              <div className="mt-3 flex gap-2">
                <label className="flex-1 cursor-pointer rounded-xl bg-emerald-600 px-3 py-2 text-center text-[11px] font-black text-white">
                  Upload
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(event) =>
                      handleSamplePhotoUpload(slot.id, event)
                    }
                    className="hidden"
                  />
                </label>

                {samplePhotosBySlotId[slot.id] && (
                  <button
                    type="button"
                    onClick={() => handleRemoveSamplePhoto(slot.id)}
                    className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-[11px] font-black text-red-700"
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

"""

if "Sample Photos" not in text:
    text = text.replace(insert_before, sample_block + insert_before, 1)

path.write_text(text)
print("PATCH:", path)
PY

echo "10D2F mini done."
