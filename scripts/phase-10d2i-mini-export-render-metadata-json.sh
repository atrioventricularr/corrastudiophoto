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

marker = """  const handleClearSamplePhotos = () => {
    setSamplePhotosBySlotId({});
  };

  return ("""

handler = """  const handleClearSamplePhotos = () => {
    setSamplePhotosBySlotId({});
  };

  const handleDownloadRenderMetadata = () => {
    const metadata = {
      generatedAt: new Date().toISOString(),
      renderMode,
      renderInfo,
      template: {
        id: activeTemplate.id,
        name: activeTemplate.name,
        customerFacingName: activeTemplate.customerFacingName,
        status: activeTemplate.status,
        layoutId: activeTemplate.layoutId,
        layoutName: activeTemplate.layoutName,
        paperSnapshot: activeTemplate.paperSnapshot,
        assetCount: activeTemplate.assets.length,
        layerCount: activeTemplate.layers.length,
        frameOverlayAssetId: activeTemplate.frameOverlayAssetId,
        backgroundAssetId: activeTemplate.backgroundAssetId,
      },
      layout: {
        id: renderLayout.id,
        name: renderLayout.name,
        mode: renderLayout.mode,
        slotCount: renderLayout.slots.length,
        slots: renderLayout.slots,
      },
      samplePhotos: {
        count: samplePhotoCount,
        slotIds: Object.keys(samplePhotosBySlotId),
      },
      printerProfile: {
        id: printerProfile.id,
        name: printerProfile.name,
        printerType: printerProfile.printerType,
        printerModel: printerProfile.printerModel,
        paperName: printerProfile.paperName,
        dpi: printerProfile.dpi,
        borderless: printerProfile.borderless,
        rotateBeforePrint: printerProfile.rotateBeforePrint,
        marginPx: printerProfile.marginPx,
        offsetPx: printerProfile.offsetPx,
        scalePercent: printerProfile.scalePercent,
      },
      layers: activeTemplate.layers,
      assets: activeTemplate.assets.map((asset) => ({
        id: asset.id,
        kind: asset.kind,
        source: asset.source,
        name: asset.name,
        mimeType: asset.mimeType,
        widthPx: asset.widthPx,
        heightPx: asset.heightPx,
        fileSizeBytes: asset.fileSizeBytes,
      })),
    };

    const safeName = activeTemplate.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    const blob = new Blob([JSON.stringify(metadata, null, 2)], {
      type: 'application/json',
    });

    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    link.href = url;
    link.download = `${safeName || 'corra-template'}-render-metadata.json`;
    document.body.appendChild(link);
    link.click();
    link.remove();

    window.setTimeout(() => URL.revokeObjectURL(url), 1000);
  };

  return ("""

if "handleDownloadRenderMetadata" not in text:
    if marker not in text:
        raise SystemExit("Could not find handleClearSamplePhotos block.")
    text = text.replace(marker, handler, 1)

old = """        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Render Metadata
        </p>"""

new = """        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Render Metadata
          </p>

          <button
            type="button"
            onClick={handleDownloadRenderMetadata}
            className="rounded-2xl border border-slate-200 bg-white px-4 py-2 text-xs font-black text-slate-700"
          >
            Download Metadata JSON
          </button>
        </div>"""

if "Download Metadata JSON" not in text:
    if old not in text:
        raise SystemExit("Could not find Render Metadata title.")
    text = text.replace(old, new, 1)

path.write_text(text)
print("10D2I patched:", path)
PY

echo "10D2I mini done."
