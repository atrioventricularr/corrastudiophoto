import React, { useMemo, useState } from 'react';
import {
  getCloudUploadRecordState,
  summarizeCloudUploadHealth,
} from './booth-cloud-upload-health';
import { loadBoothCloudUploadRecords } from './booth-cloud-upload-storage';

export function BoothCloudUploadHealthPanel() {
  const [refreshNonce, setRefreshNonce] = useState(0);

  const records = useMemo(() => {
    void refreshNonce;
    return loadBoothCloudUploadRecords();
  }, [refreshNonce]);

  const health = useMemo(() => {
    return summarizeCloudUploadHealth(records);
  }, [records]);

  const recentRecords = records.slice(-5).reverse();

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Cloud Upload Health
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Signed URL monitor untuk upload records lokal.
          </p>
        </div>

        <button
          type="button"
          onClick={() => setRefreshNonce((current) => current + 1)}
          className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
        >
          Refresh
        </button>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Total</p>
          <p className="mt-1 text-2xl font-black text-white">{health.total}</p>
        </div>

        <div className="rounded-2xl bg-emerald-500/20 p-3">
          <p className="text-xs font-black uppercase text-emerald-100">Valid</p>
          <p className="mt-1 text-2xl font-black text-white">{health.valid}</p>
        </div>

        <div className="rounded-2xl bg-amber-500/20 p-3">
          <p className="text-xs font-black uppercase text-amber-100">Expiring</p>
          <p className="mt-1 text-2xl font-black text-white">
            {health.expiringSoon}
          </p>
        </div>

        <div className="rounded-2xl bg-red-500/20 p-3">
          <p className="text-xs font-black uppercase text-red-100">Expired</p>
          <p className="mt-1 text-2xl font-black text-white">{health.expired}</p>
        </div>

        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Missing</p>
          <p className="mt-1 text-2xl font-black text-white">
            {health.missingSignedUrl}
          </p>
        </div>
      </div>

      {health.nextExpiryAt && (
        <p className="mt-3 text-xs font-bold text-white/50">
          Next expiry: {new Date(health.nextExpiryAt).toLocaleString()}
        </p>
      )}

      <div className="mt-4 grid gap-2">
        {recentRecords.length === 0 && (
          <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">
            No upload records yet.
          </div>
        )}

        {recentRecords.map((record) => {
          const state = getCloudUploadRecordState(record);

          return (
            <div key={record.id} className="rounded-2xl bg-white/10 p-3">
              <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                    {record.kind} · {state}
                  </p>
                  <p className="mt-1 break-all text-xs font-bold text-white/60">
                    {record.filename}
                  </p>
                  <p className="mt-1 text-[11px] font-bold text-white/40">
                    Expires: {new Date(record.signedUrlExpiresAt).toLocaleString()}
                  </p>
                </div>

                <a
                  href={record.signedUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
                >
                  Open
                </a>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
