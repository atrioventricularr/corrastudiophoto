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

old = """    addTemplateAsset,
    addTemplateLayer,
  } = useTemplates();"""

new = """    addTemplateAsset,
    addTemplateLayer,
    removeTemplateAsset,
  } = useTemplates();"""

if old in text and "removeTemplateAsset" not in text.split("} = useTemplates();", 1)[0]:
    text = text.replace(old, new, 1)

marker = """  const handleFramePngUpload = (
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

insert = """  const handleFramePngUpload = (
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

  const handleRemoveFramePng = () => {
    if (!frameOverlayAsset) return;

    if (window.confirm(`Remove frame "${frameOverlayAsset.name}"?`)) {
      removeTemplateAsset(activeTemplate.id, frameOverlayAsset.id);
    }
  };

  return ("""

if "handleRemoveFramePng" not in text:
    if marker not in text:
        raise SystemExit("Could not find frame upload handler.")
    text = text.replace(marker, insert, 1)

old_upload = """          <label className="cursor-pointer rounded-2xl bg-blue-600 px-5 py-3 text-center text-xs font-black text-white">
            Upload PNG
            <input
              type="file"
              accept="image/png"
              onChange={handleFramePngUpload}
              className="hidden"
            />
          </label>"""

new_upload = """          <div className="flex flex-col gap-2 sm:flex-row">
            <label className="cursor-pointer rounded-2xl bg-blue-600 px-5 py-3 text-center text-xs font-black text-white">
              Upload PNG
              <input
                type="file"
                accept="image/png"
                onChange={handleFramePngUpload}
                className="hidden"
              />
            </label>

            {frameOverlayAsset && (
              <button
                type="button"
                onClick={handleRemoveFramePng}
                className="rounded-2xl border border-red-200 bg-white px-5 py-3 text-xs font-black text-red-700"
              >
                Remove Frame
              </button>
            )}
          </div>"""

if "Remove Frame" not in text:
    if old_upload not in text:
        raise SystemExit("Could not find upload button block.")
    text = text.replace(old_upload, new_upload, 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo "10D1S mini done."
