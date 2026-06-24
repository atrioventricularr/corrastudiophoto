import React, { useMemo, useState } from 'react';
import { useBoothFlow } from './BoothFlowProvider';
import { useBoothLocalAssets } from './BoothLocalAssetProvider';
import { isCorraDiskAvailable, openBoothDiskOutputFolder, saveBoothDataUrlToDisk } from './booth-disk-persistence-api';
import { appendBoothDiskRecord } from './booth-disk-persistence-storage';

type LocalAssetLike = {
  id: string;
  sessionId?: string;
  kind?: string;
  filename?: string;
  dataUrl?: string;
};

export function BoothDeliveryDiskPanel() {
  const { session } = useBoothFlow();
  const { assets } = useBoothLocalAssets();
  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const available = isCorraDiskAvailable();
  const sessionId = session?.id || 'delivery-session';

  const latestFinalAsset = useMemo(() => {
    return assets
      .map((asset) => asset as LocalAssetLike)
      .filter((asset) => asset.kind === 'final_output')
      .filter((asset) => !session?.id || asset.sessionId === session.id)
      .at(-1);
  }, [assets, session?.id]);

  const saveFinal = async () => {
    if (!latestFinalAsset?.dataUrl) {
      setError('No final output asset found in local assets.');
      return;
    }

    setIsSaving(true);
    setMessage('');
    setError('');

    try {
      const record = await saveBoothDataUrlToDisk({
        sessionId,
        kind: 'final_output',
        filename: latestFinalAsset.filename || `final-output-${sessionId}.png`,
        dataUrl: latestFinalAsset.dataUrl,
        metadata: { localAssetId: latestFinalAsset.id, source: 'delivery-step' },
      });
      appendBoothDiskRecord(record);
      setMessage('Final output saved to disk.');
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Failed to save final output.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <section className="rounded-[2rem] border border-white/10 bg-white/10 p-6">
      <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
        Disk Copy
      </p>
      <p className="mt-2 text-sm font-bold text-white/60">
        Save final output to the local Electron output folder.
      </p>

      {!available && (
        <div className="mt-4 rounded-2xl bg-amber-500/20 p-3 text-xs font-bold text-amber-100">
          Disk persistence only works inside Electron.
        </div>
      )}

      <div className="mt-4 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => void saveFinal()}
          disabled={!available || isSaving || !latestFinalAsset}
          className="rounded-2xl bg-white px-4 py-3 text-xs font-black text-slate-950 disabled:opacity-40"
        >
          {isSaving ? 'Saving...' : 'Save Final to Disk'}
        </button>
        <button
          type="button"
          onClick={() => void openBoothDiskOutputFolder(sessionId)}
          disabled={!available}
          className="rounded-2xl border border-white/15 bg-white/10 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
        >
          Open Session Folder
        </button>
      </div>

      {message && <p className="mt-3 text-xs font-bold text-emerald-200">{message}</p>}
      {error && <p className="mt-3 text-xs font-bold text-red-200">{error}</p>}
    </section>
  );
}
