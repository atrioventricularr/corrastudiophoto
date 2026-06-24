import React, { useMemo, useState } from 'react';
import { useBoothFlow } from './BoothFlowProvider';
import { useBoothLocalAssets } from './BoothLocalAssetProvider';
import { buildBoothDiskManifest, makeBoothManifestFilename } from './booth-disk-manifest';
import {
  isCorraDiskAvailable,
  openBoothDiskOutputFolder,
  saveBoothDataUrlToDisk,
  saveBoothTextToDisk,
} from './booth-disk-persistence-api';
import type { BoothDiskFileRecord } from './booth-disk-persistence-types';
import {
  appendBoothDiskRecord,
  clearBoothDiskRecords,
  loadBoothDiskRecords,
  saveBoothDiskRecords,
} from './booth-disk-persistence-storage';

type LocalAssetLike = {
  id: string;
  sessionId?: string;
  kind?: string;
  filename?: string;
  dataUrl?: string;
  createdAt?: string;
};

function asLocalAssetLike(value: unknown): LocalAssetLike {
  return value as LocalAssetLike;
}

export function BoothDiskPersistencePanel() {
  const { session } = useBoothFlow();
  const { assets, refreshAssets } = useBoothLocalAssets();
  const [records, setRecords] = useState(() => loadBoothDiskRecords());
  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const available = isCorraDiskAvailable();
  const currentSessionId = session?.id || 'manual-session';

  const unsavedAssets = useMemo(() => {
    const savedAssetIds = new Set(
      records
        .map((record) => record.metadata?.localAssetId)
        .filter((value): value is string => typeof value === 'string'),
    );

    return assets
      .map(asLocalAssetLike)
      .filter((asset) => !savedAssetIds.has(asset.id));
  }, [assets, records]);

  const refreshRecords = () => setRecords(loadBoothDiskRecords());

  const saveAssetsToDisk = async () => {
    setIsSaving(true);
    setMessage('');
    setError('');

    try {
      await refreshAssets();
      let nextRecords = loadBoothDiskRecords();
      let savedCount = 0;

      for (const asset of unsavedAssets) {
        if (!asset.dataUrl) continue;

        const record = await saveBoothDataUrlToDisk({
          sessionId: asset.sessionId || currentSessionId,
          kind: asset.kind || 'other',
          filename: asset.filename || `${asset.kind || 'asset'}-${asset.id}.png`,
          dataUrl: asset.dataUrl,
          metadata: {
            localAssetId: asset.id,
            localCreatedAt: asset.createdAt,
            source: 'booth-local-assets',
          },
        });

        nextRecords = appendBoothDiskRecord(record);
        savedCount += 1;
      }

      setRecords(nextRecords);
      setMessage(`Saved ${savedCount} local asset(s) to Electron disk.`);
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to save local assets to disk.',
      );
    } finally {
      setIsSaving(false);
    }
  };

  const saveManifest = async () => {
    setIsSaving(true);
    setMessage('');
    setError('');

    try {
      const latestRecords = loadBoothDiskRecords().filter(
        (record) => record.sessionId === currentSessionId,
      );
      const manifest = buildBoothDiskManifest({
        sessionId: currentSessionId,
        records: latestRecords,
        extra: { localAssetCount: assets.length },
      });

      const record = await saveBoothTextToDisk({
        sessionId: currentSessionId,
        kind: 'manifest',
        filename: makeBoothManifestFilename(currentSessionId),
        text: JSON.stringify(manifest, null, 2),
        mimeType: 'application/json',
        metadata: { source: 'booth-disk-persistence-panel' },
      });

      const nextRecords = appendBoothDiskRecord(record);
      setRecords(nextRecords);
      setMessage('Session manifest saved to disk.');
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Failed to save manifest.');
    } finally {
      setIsSaving(false);
    }
  };

  const openFolder = async () => {
    try {
      await openBoothDiskOutputFolder(currentSessionId);
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Failed to open output folder.');
    }
  };

  const clearLocalRecords = () => {
    clearBoothDiskRecords();
    saveBoothDiskRecords([]);
    setRecords([]);
    setMessage('Local disk record registry cleared. Files on disk are not deleted.');
  };

  const recentRecords: BoothDiskFileRecord[] = records.slice(-6).reverse();

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Electron Disk Persistence
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Save local raw/final assets to app userData for production booth operation.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void saveAssetsToDisk()}
            disabled={!available || isSaving || unsavedAssets.length === 0}
            className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950 disabled:opacity-40"
          >
            {isSaving ? 'Saving...' : `Save Assets (${unsavedAssets.length})`}
          </button>

          <button
            type="button"
            onClick={() => void saveManifest()}
            disabled={!available || isSaving}
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white disabled:opacity-40"
          >
            Save Manifest
          </button>

          <button
            type="button"
            onClick={() => void openFolder()}
            disabled={!available}
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white disabled:opacity-40"
          >
            Open Folder
          </button>
        </div>
      </div>

      {!available && (
        <div className="mt-4 rounded-2xl bg-amber-500/20 p-3 text-xs font-bold text-amber-100">
          Electron disk bridge belum tersedia. Buka dari Electron app, bukan browser Vite biasa.
        </div>
      )}

      {message && (
        <div className="mt-4 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">
          {message}
        </div>
      )}

      {error && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          {error}
        </div>
      )}

      <div className="mt-4 grid gap-3 sm:grid-cols-3">
        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Local Assets</p>
          <p className="mt-1 text-2xl font-black text-white">{assets.length}</p>
        </div>
        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Unsaved</p>
          <p className="mt-1 text-2xl font-black text-white">{unsavedAssets.length}</p>
        </div>
        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Disk Records</p>
          <p className="mt-1 text-2xl font-black text-white">{records.length}</p>
        </div>
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={refreshRecords}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
        >
          Refresh Records
        </button>
        <button
          type="button"
          onClick={clearLocalRecords}
          className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
        >
          Clear Registry Only
        </button>
      </div>

      <div className="mt-4 grid gap-2">
        {recentRecords.length === 0 && (
          <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">
            No disk records yet.
          </div>
        )}

        {recentRecords.map((record) => (
          <div key={record.id} className="rounded-2xl bg-white/10 p-3">
            <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
              {record.kind} · {Math.round(record.sizeBytes / 1024)} KB
            </p>
            <p className="mt-1 break-all text-xs font-bold text-white/60">
              {record.relativePath}
            </p>
            <p className="mt-1 text-[11px] font-bold text-white/40">
              Saved: {new Date(record.savedAt).toLocaleString()}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
