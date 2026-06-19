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

# Ensure removeTemplateAsset exists
old = """    addTemplateAsset,
    addTemplateLayer,
  } = useTemplates();"""

new = """    addTemplateAsset,
    addTemplateLayer,
    removeTemplateAsset,
  } = useTemplates();"""

if old in text and "removeTemplateAsset" not in text.split("} = useTemplates();", 1)[0]:
    text = text.replace(old, new, 1)

# Add remove background handler
marker = """  const handleBackgroundUpload = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (!file.type.startsWith('image/')) {
      window.alert('Background harus file image.');
      event.target.value = '';
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result !== 'string') return;

      const asset = createTemplateAsset({
        kind: 'background',
        source: 'local',
        name: file.name,
        url: reader.result,
        mimeType: file.type,
        fileSizeBytes: file.size,
      });

      const layer = createTemplateLayer({
        name: 'Background',
        assetId: asset.id,
        kind: 'background',
        zIndex: 0,
        opacity: 1,
        visible: true,
      });

      addTemplateAsset(activeTemplate.id, asset);
      addTemplateLayer(activeTemplate.id, layer);
      updateTemplate(activeTemplate.id, {
        backgroundAssetId: asset.id,
        status: 'draft',
      });
    };

    reader.readAsDataURL(file);
    event.target.value = '';
  };

  return ("""

insert = """  const handleBackgroundUpload = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];

    if (!file) return;

    if (!file.type.startsWith('image/')) {
      window.alert('Background harus file image.');
      event.target.value = '';
      return;
    }

    const reader = new FileReader();

    reader.onload = () => {
      if (typeof reader.result !== 'string') return;

      const asset = createTemplateAsset({
        kind: 'background',
        source: 'local',
        name: file.name,
        url: reader.result,
        mimeType: file.type,
        fileSizeBytes: file.size,
      });

      const layer = createTemplateLayer({
        name: 'Background',
        assetId: asset.id,
        kind: 'background',
        zIndex: 0,
        opacity: 1,
        visible: true,
      });

      addTemplateAsset(activeTemplate.id, asset);
      addTemplateLayer(activeTemplate.id, layer);
      updateTemplate(activeTemplate.id, {
        backgroundAssetId: asset.id,
        status: 'draft',
      });
    };

    reader.readAsDataURL(file);
    event.target.value = '';
  };

  const handleRemoveBackground = () => {
    if (!backgroundAsset) return;

    if (window.confirm(`Remove background "${backgroundAsset.name}"?`)) {
      removeTemplateAsset(activeTemplate.id, backgroundAsset.id);
    }
  };

  return ("""

if "handleRemoveBackground" not in text:
    if marker not in text:
        raise SystemExit("Could not find background upload handler.")
    text = text.replace(marker, insert, 1)

# Replace upload background label with upload + remove group
old_block = """          <label className="cursor-pointer rounded-2xl bg-purple-600 px-5 py-3 text-center text-xs font-black text-white">
            Upload Background
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={handleBackgroundUpload}
              className="hidden"
            />
          </label>"""

new_block = """          <div className="flex flex-col gap-2 sm:flex-row">
            <label className="cursor-pointer rounded-2xl bg-purple-600 px-5 py-3 text-center text-xs font-black text-white">
              Upload Background
              <input
                type="file"
                accept="image/png,image/jpeg,image/webp"
                onChange={handleBackgroundUpload}
                className="hidden"
              />
            </label>

            {backgroundAsset && (
              <button
                type="button"
                onClick={handleRemoveBackground}
                className="rounded-2xl border border-red-200 bg-white px-5 py-3 text-xs font-black text-red-700"
              >
                Remove Background
              </button>
            )}
          </div>"""

if "Remove Background" not in text:
    if old_block not in text:
        raise SystemExit("Could not find background upload button.")
    text = text.replace(old_block, new_block, 1)

path.write_text(text)
print("PATCH:", path)
PY

echo "10D1W mini done."
