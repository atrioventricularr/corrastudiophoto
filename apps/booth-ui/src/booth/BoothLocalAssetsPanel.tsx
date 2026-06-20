import React, { useMemo } from 'react';
import {
  downloadBoothLocalAsset,
  formatAssetSize,
} from './booth-local-assets-db';
import { useBoothFlow } from './BoothFlowProvider';
import { useBoothLocalAssets } from './BoothLocalAssetProvider';

function downloadJson(filename: string, data: unknown) {
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json',
  });

  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');

  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();

  URL.revokeObjectURL(url);
}

export function BoothLocalAssetsPanel() {
  const {
    session,
  } = useBoothFlow();

  const {
    assets,
    isLoading,
    error,
    summary,
    refreshAssets,
    deleteAsset,
    clearSessionAssets,
    clearAllAssets,
  } = useBoothLocalAssets();

  const sessionAssets = useMemo(() => {
    if (!session?.id) return [];

    return assets.filter((asset) => asset.sessionId === session.id);
  }, [
    assets,
    session?.id,
  ]);

  const recentAssets = assets.slice(0, 8);

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Local Asset Registry
          </p>

          <p className="mt-1 text-sm font-bold text-white/60">
            {isLoading
              ? 'Loading local assets...'
              : `${summary.totalAssets} asset(s), ${formatAssetSize(
                  summary.totalSizeBytes,
                )}`}
          </p>

          <p className="mt-1 text-xs font-bold text-white/40">
            Raw: {summary.rawCaptureCount} · Final: {summary.finalOutputCount} ·
            Current session: {sessionAssets.length}
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void refreshAssets()}
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
          >
            Refresh
          </button>

          <button
            type="button"
            onClick={() =>
              downloadJson(
                `corra-booth-assets-${new Date()
                  .toISOString()
                  .replace(/[:.]/g, '-')}.json`,
                assets.map((asset) => ({
                  ...asset,
                  dataUrl: `[stored data url: ${asset.dataUrl.length} chars]`,
                })),
              )
            }
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
          >
            Export Registry
          </button>

          {session?.id && (
            <button
              type="button"
              onClick={() => void clearSessionAssets(session.id)}
              className="rounded-2xl border border-amber-300/30 bg-amber-500/20 px-3 py-2 text-xs font-black text-amber-100"
            >
              Clear Session
            </button>
          )}

          <button
            type="button"
            onClick={() => void clearAllAssets()}
            className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
          >
            Clear All
          </button>
        </div>
      </div>

      {error && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          {error}
        </div>
      )}

      <div className="mt-4 grid gap-2">
        {recentAssets.length === 0 && (
          <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">
            Belum ada local asset. Capture foto atau render final output dulu.
          </div>
        )}

        {recentAssets.map((asset) => (
          <div
            key={asset.id}
            className="rounded-2xl bg-white/10 p-3"
          >
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                  {asset.kind}
                </p>

                <p className="mt-1 break-all text-xs font-bold text-white/60">
                  {asset.filename}
                </p>

                <p className="mt-1 text-[11px] font-bold text-white/40">
                  {formatAssetSize(asset.sizeBytes)} ·{' '}
                  {new Date(asset.createdAt).toLocaleString()}
                </p>

                <p className="mt-1 break-all font-mono text-[10px] font-bold text-white/35">
                  {asset.sessionId}
                </p>
              </div>

              <div className="flex shrink-0 flex-wrap gap-2">
                <button
                  type="button"
                  onClick={() => downloadBoothLocalAsset(asset)}
                  className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
                >
                  Download
                </button>

                <button
                  type="button"
                  onClick={() => void deleteAsset(asset.id)}
                  className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-4 rounded-2xl bg-black/20 p-3">
        <p className="text-xs font-bold text-white/45">
          Storage: IndexedDB. Ini persist di browser/app local selama user tidak
          clear site data. Nanti Electron phase bisa map registry ini ke folder
          local Windows.
        </p>
      </div>
    </section>
  );
}
