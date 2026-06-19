#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: TemplateAdminPanel.tsx not found."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/admin/TemplateAdminPanel.tsx")
text = path.read_text()

# 1. Add template asset utilities to import.
text = text.replace(
    "import { createPaperSnapshotFromLayout, createPhotoTemplate, useTemplates } from '../../templates';",
    "import { createPaperSnapshotFromLayout, createPhotoTemplate, createTemplateAsset, createTemplateLayer, useTemplates } from '../../templates';",
)

# 2. Add asset/layer actions to useTemplates destructuring.
old = """    updateTemplate,
    removeTemplate,
  } = useTemplates();"""

new = """    updateTemplate,
    removeTemplate,
    addTemplateAsset,
    addTemplateLayer,
  } = useTemplates();"""

if old in text and "addTemplateAsset" not in text.split("} = useTemplates();", 1)[0]:
    text = text.replace(old, new, 1)

# 3. Add handler before return.
marker = """  const handleDuplicateActiveTemplate = () => {
    const now = new Date().toISOString();

    addTemplate({
      ...activeTemplate,
      id: `template-copy-${Date.now()}`,
      name: `${activeTemplate.name} Copy`,
      customerFacingName: `${activeTemplate.customerFacingName} Copy`,
      status: 'draft',
      notes: `Duplicated from ${activeTemplate.name}.`,
      createdAt: now,
      updatedAt: now,
    });
  };

  return ("""

insert = """  const handleDuplicateActiveTemplate = () => {
    const now = new Date().toISOString();

    addTemplate({
      ...activeTemplate,
      id: `template-copy-${Date.now()}`,
      name: `${activeTemplate.name} Copy`,
      customerFacingName: `${activeTemplate.customerFacingName} Copy`,
      status: 'draft',
      notes: `Duplicated from ${activeTemplate.name}.`,
      createdAt: now,
      updatedAt: now,
    });
  };

  const frameOverlayAsset = activeTemplate.assets.find(
    (asset) => asset.id === activeTemplate.frameOverlayAssetId,
  );

  const handleFramePngUpload = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (file.type !== 'image/png') {
      window.alert('Frame overlay harus PNG.');
      event.target.value = '';
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result !== 'string') return;

      const asset = createTemplateAsset({
        kind: 'frame-overlay',
        source: 'local',
        name: file.name,
        url: reader.result,
        mimeType: file.type,
        fileSizeBytes: file.size,
      });

      const layer = createTemplateLayer({
        name: 'Frame Overlay',
        assetId: asset.id,
        kind: 'frame-overlay',
        zIndex: 100,
        opacity: 1,
        visible: true,
      });

      addTemplateAsset(activeTemplate.id, asset);
      addTemplateLayer(activeTemplate.id, layer);
      updateTemplate(activeTemplate.id, {
        frameOverlayAssetId: asset.id,
        status: 'draft',
      });
    };

    reader.readAsDataURL(file);
    event.target.value = '';
  };

  return ("""

if "handleFramePngUpload" not in text:
    if marker not in text:
        raise SystemExit("Could not find duplicate handler marker.")
    text = text.replace(marker, insert, 1)

# 4. Insert upload UI before old placeholder.
placeholder = """      <div className="mt-5 rounded-3xl border border-dashed border-slate-300 bg-slate-50 p-5 text-center">"""

block = """      <div className="mt-5 rounded-3xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
          Frame PNG Overlay
        </p>

        <div className="mt-4 grid gap-4 lg:grid-cols-[1fr_auto] lg:items-center">
          <div>
            <p className="text-sm font-black text-blue-950">
              {frameOverlayAsset?.name || 'No frame PNG uploaded yet'}
            </p>
            <p className="mt-1 text-xs font-bold text-blue-700">
              PNG frame akan jadi layer paling atas di final output.
            </p>
          </div>

          <label className="cursor-pointer rounded-2xl bg-blue-600 px-5 py-3 text-center text-xs font-black text-white">
            Upload PNG
            <input
              type="file"
              accept="image/png"
              onChange={handleFramePngUpload}
              className="hidden"
            />
          </label>
        </div>

        {frameOverlayAsset?.url && (
          <div className="mt-4 rounded-2xl bg-white p-3">
            <img
              src={frameOverlayAsset.url}
              alt={frameOverlayAsset.name}
              className="mx-auto max-h-40 object-contain"
            />
          </div>
        )}
      </div>

"""

if "Frame PNG Overlay" not in text:
    if placeholder not in text:
        raise SystemExit("Could not find old frame upload placeholder.")
    text = text.replace(placeholder, block + placeholder, 1)

# 5. Update placeholder text because upload now exists.
text = text.replace(
    "Frame PNG upload belum dipasang.",
    "Frame PNG upload sudah basic."
)
text = text.replace(
    "Next phase baru kita tambah upload frame overlay + layer template.",
    "Next phase kita tampilkan frame overlay di template preview."
)

path.write_text(text)
print("PATCH file:", path)
PY

echo "10D1Q mini done."
