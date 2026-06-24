import React, { useState } from 'react';
import {
  deleteBoothDiskFile,
  isCorraDiskAvailable,
  listBoothDiskFiles,
  openBoothDiskOutputFolder,
} from './booth-disk-persistence-api';
import { removeBoothDiskRecordByRelativePath } from './booth-disk-persistence-storage';

type ListedFile = {
  relativePath: string;
  filename: string;
  sizeBytes: number;
  modifiedAt: string;
};

export function BoothDiskBrowserPanel() {
  const [files, setFiles] = useState<ListedFile[]>([]);
  const [sessionId, setSessionId] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const available = isCorraDiskAvailable();

  const refresh = async () => {
    setMessage('');
    setError('');
    try {
      const result = await listBoothDiskFiles(sessionId.trim() || undefined);
      setFiles(result.files || []);
      setMessage(`Loaded ${result.files?.length || 0} disk file(s).`);
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Failed to list disk files.');
    }
  };

  const deleteFile = async (relativePath: string) => {
    setError('');
    try {
      await deleteBoothDiskFile(relativePath);
      removeBoothDiskRecordByRelativePath(relativePath);
      setFiles(files.filter((file) => file.relativePath !== relativePath));
      setMessage('Disk file deleted.');
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : 'Failed to delete disk file.');
    }
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Disk File Browser
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Browse files saved under Electron userData/corra-booth-output.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void openBoothDiskOutputFolder(sessionId.trim() || undefined)}
          disabled={!available}
          className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950 disabled:opacity-40"
        >
          Open Folder
        </button>
      </div>

      <div className="mt-4 flex flex-col gap-2 sm:flex-row">
        <input
          value={sessionId}
          onChange={(event) => setSessionId(event.target.value)}
          placeholder="Optional session id"
          className="min-w-0 flex-1 rounded-2xl border border-white/10 bg-white/10 px-3 py-2 text-xs font-bold text-white outline-none placeholder:text-white/30"
        />
        <button
          type="button"
          onClick={() => void refresh()}
          disabled={!available}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white disabled:opacity-40"
        >
          Refresh Files
        </button>
      </div>

      {message && <div className="mt-4 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">{message}</div>}
      {error && <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">{error}</div>}

      <div className="mt-4 grid gap-2">
        {files.slice(-12).reverse().map((file) => (
          <div key={file.relativePath} className="rounded-2xl bg-white/10 p-3">
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <p className="break-all text-xs font-black text-white">{file.relativePath}</p>
                <p className="mt-1 text-[11px] font-bold text-white/40">
                  {Math.round(file.sizeBytes / 1024)} KB · {new Date(file.modifiedAt).toLocaleString()}
                </p>
              </div>
              <button
                type="button"
                onClick={() => void deleteFile(file.relativePath)}
                className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
              >
                Delete
              </button>
            </div>
          </div>
        ))}
        {files.length === 0 && <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">No disk files loaded.</div>}
      </div>
    </section>
  );
}
