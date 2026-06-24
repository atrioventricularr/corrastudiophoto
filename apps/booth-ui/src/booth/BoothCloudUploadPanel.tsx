import React, {
  useMemo,
  useState,
} from 'react';
import {
  formatAssetSize,
} from './booth-local-assets-db';
import type {
  BoothLocalAssetRecord,
} from './booth-local-asset-types';
import {
  createBoothCloudUploadRecord,
  getBoothUploadAssetUrl,
  uploadBoothLocalAssetToCloud,
} from './booth-cloud-upload-api';
import {
  clearBoothCloudUploadRecords,
  loadBoothCloudUploadRecords,
  saveBoothCloudUploadRecords,
} from './booth-cloud-upload-storage';
import type {
  BoothCloudUploadRecord,
} from './booth-cloud-upload-types';
import { useBoothFlow } from './BoothFlowProvider';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';
import { useBoothLocalAssets } from './BoothLocalAssetProvider';

function copyToClipboard(value: string) {
  if (navigator.clipboard?.writeText) {
    return navigator.clipboard.writeText(value);
  }

  const textarea = document.createElement('textarea');
  textarea.value = value;
  textarea.style.position = 'fixed';
  textarea.style.opacity = '0';
  document.body.appendChild(textarea);
  textarea.focus();
  textarea.select();
  document.execCommand('copy');
  textarea.remove();

  return Promise.resolve();
}

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

export function BoothCloudUploadPanel() {
  const {
    session,
    currentStep,
    paymentStatus,
  } = useBoothFlow();

  const {
    assets,
    refreshAssets,
  } = useBoothLocalAssets();

  const {
    recordBoothEvent,
  } = useBoothLifecycleLogger();

  const [uploadRecords, setUploadRecords] = useState<
    BoothCloudUploadRecord[]
  >(() => loadBoothCloudUploadRecords());

  const [isUploading, setIsUploading] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const uploadUrl = getBoothUploadAssetUrl();

  const currentSessionAssets = useMemo(() => {
    if (!session?.id) return [];

    return assets.filter((asset) => asset.sessionId === session.id);
  }, [
    assets,
    session?.id,
  ]);

  const finalOutputAssets = useMemo(() => {
    return currentSessionAssets.filter(
      (asset) => asset.kind === 'final_output',
    );
  }, [currentSessionAssets]);

  const recentUploadRecords = uploadRecords.slice(-8).reverse();

  const saveRecords = (records: BoothCloudUploadRecord[]) => {
    saveBoothCloudUploadRecords(records);
    setUploadRecords(records);
  };

  const hasUploadedAsset = (asset: BoothLocalAssetRecord) => {
    return uploadRecords.some((record) => record.localAssetId === asset.id);
  };

  const uploadOneAsset = async (asset: BoothLocalAssetRecord) => {
    const result = await uploadBoothLocalAssetToCloud(asset);
    const record = createBoothCloudUploadRecord({
      asset,
      result,
    });

    return record;
  };

  const uploadAssets = async (
    inputAssets: BoothLocalAssetRecord[],
    label: string,
  ) => {
    setIsUploading(true);
    setMessage('');
    setError('');

    try {
      await refreshAssets();

      const filteredAssets = inputAssets.filter((asset) => !hasUploadedAsset(asset));

      if (filteredAssets.length === 0) {
        setMessage(`No new ${label} assets to upload.`);
        return;
      }

      const nextRecords = [...uploadRecords];

      for (const asset of filteredAssets) {
        const record = await uploadOneAsset(asset);
        nextRecords.push(record);

        recordBoothEvent({
          type: 'debug_note',
          summary: `Uploaded ${asset.kind} to Supabase Storage.`,
          sessionId: asset.sessionId,
          step: currentStep,
          paymentStatus,
          payload: {
            localAssetId: asset.id,
            bucketName: record.bucketName,
            storagePath: record.storagePath,
            signedUrlExpiresAt: record.signedUrlExpiresAt,
          },
        });
      }

      saveRecords(nextRecords);

      setMessage(
        `Uploaded ${filteredAssets.length} ${label} asset(s) to Supabase.`,
      );
    } catch (caughtError) {
      setError(
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to upload booth assets.',
      );
    } finally {
      setIsUploading(false);
    }
  };

  const clearRecords = () => {
    clearBoothCloudUploadRecords();
    setUploadRecords([]);
    setMessage('Local cloud upload records cleared.');
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Cloud Upload
          </p>

          <p className="mt-1 text-sm font-bold text-white/60">
            Upload local raw/final assets to Supabase Storage and generate
            signed share links.
          </p>

          <p className="mt-1 text-xs font-bold text-white/40">
            Current session assets: {currentSessionAssets.length} · Finals:{' '}
            {finalOutputAssets.length} · Uploaded: {uploadRecords.length}
          </p>
        </div>

        <span
          className={`rounded-full px-3 py-1 text-xs font-black text-white ${
            uploadUrl ? 'bg-emerald-600' : 'bg-red-600'
          }`}
        >
          {uploadUrl ? 'Configured' : 'Missing URL'}
        </span>
      </div>

      {!uploadUrl && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          VITE_UPLOAD_BOOTH_ASSET_URL belum ada. Deploy Edge Function dan cek
          .env.local.
        </div>
      )}

      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <button
          type="button"
          onClick={() => void uploadAssets(currentSessionAssets, 'session')}
          disabled={isUploading || !uploadUrl || currentSessionAssets.length === 0}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950 disabled:opacity-40"
        >
          Upload Session
        </button>

        <button
          type="button"
          onClick={() => void uploadAssets(finalOutputAssets, 'final output')}
          disabled={isUploading || !uploadUrl || finalOutputAssets.length === 0}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-3 text-xs font-black text-white disabled:opacity-40"
        >
          Upload Finals
        </button>

        <button
          type="button"
          onClick={() => void uploadAssets(assets, 'all local')}
          disabled={isUploading || !uploadUrl || assets.length === 0}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-3 text-xs font-black text-white disabled:opacity-40"
        >
          Upload All
        </button>

        <button
          type="button"
          onClick={clearRecords}
          disabled={isUploading || uploadRecords.length === 0}
          className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-3 text-xs font-black text-red-100 disabled:opacity-40"
        >
          Clear Records
        </button>
      </div>

      {isUploading && (
        <div className="mt-4 rounded-2xl bg-blue-500/20 p-3 text-xs font-bold text-blue-100">
          Uploading assets to Supabase...
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

      <div className="mt-4 grid gap-2">
        {recentUploadRecords.length === 0 && (
          <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">
            No cloud uploads yet.
          </div>
        )}

        {recentUploadRecords.map((record) => (
          <div
            key={record.id}
            className="rounded-2xl bg-white/10 p-3"
          >
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                  {record.kind}
                </p>

                <p className="mt-1 break-all text-xs font-bold text-white/60">
                  {record.filename}
                </p>

                <p className="mt-1 text-[11px] font-bold text-white/40">
                  {record.bucketName} · {formatAssetSize(record.sizeBytes)}
                </p>

                <p className="mt-1 break-all font-mono text-[10px] font-bold text-white/35">
                  {record.storagePath}
                </p>
              </div>

              <div className="flex shrink-0 flex-wrap gap-2">
                <a
                  href={record.signedUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
                >
                  Open
                </a>

                <button
                  type="button"
                  onClick={() => void copyToClipboard(record.signedUrl)}
                  className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
                >
                  Copy Link
                </button>
              </div>
            </div>

            <p className="mt-2 text-[11px] font-bold text-white/40">
              Link expires:{' '}
              {new Date(record.signedUrlExpiresAt).toLocaleString()}
            </p>
          </div>
        ))}
      </div>

      {uploadRecords.length > 0 && (
        <button
          type="button"
          onClick={() =>
            downloadJson(
              `corra-cloud-upload-records-${new Date()
                .toISOString()
                .replace(/[:.]/g, '-')}.json`,
              uploadRecords,
            )
          }
          className="mt-4 rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
        >
          Export Upload Records
        </button>
      )}
    </section>
  );
}
