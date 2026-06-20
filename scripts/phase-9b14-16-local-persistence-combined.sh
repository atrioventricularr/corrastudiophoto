#!/usr/bin/env bash
set -euo pipefail

echo "================================================="
echo " Phase 9B14-16 - Local Persistence Combined"
echo "================================================="

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/booth-local-asset-types.ts <<'TS'
export type BoothLocalAssetKind =
  | 'raw_capture'
  | 'final_output';

export type BoothLocalAssetRecord = {
  id: string;
  sessionId: string;
  kind: BoothLocalAssetKind;
  dataUrl: string;
  filename: string;
  mimeType: string;
  sizeBytes: number;
  createdAt: string;
  updatedAt: string;
  slotId?: string;
  outputId?: string;
  templateId?: string;
  templateName?: string;
  layoutId?: string;
  layoutName?: string;
  renderMode?: string;
  widthPx?: number;
  heightPx?: number;
  source?: string;
  metadata?: Record<string, unknown>;
};

export type SaveBoothLocalAssetInput = {
  sessionId: string;
  kind: BoothLocalAssetKind;
  dataUrl: string;
  filename?: string;
  mimeType?: string;
  slotId?: string;
  outputId?: string;
  templateId?: string;
  templateName?: string;
  layoutId?: string;
  layoutName?: string;
  renderMode?: string;
  widthPx?: number;
  heightPx?: number;
  source?: string;
  metadata?: Record<string, unknown>;
};

export type BoothLocalAssetSummary = {
  totalAssets: number;
  rawCaptureCount: number;
  finalOutputCount: number;
  totalSizeBytes: number;
};
TS

cat > apps/booth-ui/src/booth/booth-local-assets-db.ts <<'TS'
import type {
  BoothLocalAssetRecord,
  BoothLocalAssetSummary,
  SaveBoothLocalAssetInput,
} from './booth-local-asset-types';

const DB_NAME = 'corra-booth-local-assets';
const DB_VERSION = 1;
const STORE_NAME = 'assets';

function createId(prefix: string) {
  if (
    typeof window !== 'undefined' &&
    window.crypto &&
    typeof window.crypto.randomUUID === 'function'
  ) {
    return `${prefix}-${window.crypto.randomUUID()}`;
  }

  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function estimateDataUrlSizeBytes(dataUrl: string) {
  const commaIndex = dataUrl.indexOf(',');
  const payload = commaIndex >= 0 ? dataUrl.slice(commaIndex + 1) : dataUrl;

  if (!payload) return 0;

  if (dataUrl.includes(';base64,')) {
    const padding = payload.endsWith('==') ? 2 : payload.endsWith('=') ? 1 : 0;
    return Math.max(0, Math.floor((payload.length * 3) / 4) - padding);
  }

  try {
    return new Blob([decodeURIComponent(payload)]).size;
  } catch {
    return new Blob([payload]).size;
  }
}

export function inferMimeTypeFromDataUrl(dataUrl: string) {
  const match = dataUrl.match(/^data:([^;,]+)[;,]/);
  return match?.[1] || 'image/png';
}

export function buildBoothAssetFilename(input: {
  sessionId: string;
  kind: 'raw_capture' | 'final_output';
  slotId?: string;
  outputId?: string;
  renderMode?: string;
}) {
  const shortSession = input.sessionId
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .slice(-14);

  const timestamp = new Date()
    .toISOString()
    .replace(/[:.]/g, '-');

  if (input.kind === 'raw_capture') {
    const safeSlot = (input.slotId || 'slot')
      .replace(/[^a-zA-Z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');

    return `corra-${shortSession}-${safeSlot}-raw-${timestamp}.png`;
  }

  const safeMode = (input.renderMode || 'final')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  return `corra-${shortSession}-${safeMode}-final-${timestamp}.png`;
}

function assertIndexedDbAvailable() {
  if (typeof window === 'undefined' || !window.indexedDB) {
    throw new Error('IndexedDB is not available in this environment.');
  }
}

function openBoothAssetsDb(): Promise<IDBDatabase> {
  assertIndexedDbAvailable();

  return new Promise((resolve, reject) => {
    const request = window.indexedDB.open(DB_NAME, DB_VERSION);

    request.onerror = () => {
      reject(request.error || new Error('Failed to open booth assets database.'));
    };

    request.onsuccess = () => {
      resolve(request.result);
    };

    request.onupgradeneeded = () => {
      const db = request.result;

      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const store = db.createObjectStore(STORE_NAME, {
          keyPath: 'id',
        });

        store.createIndex('sessionId', 'sessionId', {
          unique: false,
        });

        store.createIndex('kind', 'kind', {
          unique: false,
        });

        store.createIndex('createdAt', 'createdAt', {
          unique: false,
        });
      }
    };
  });
}

function requestToPromise<T>(request: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    request.onerror = () => {
      reject(request.error || new Error('IndexedDB request failed.'));
    };

    request.onsuccess = () => {
      resolve(request.result);
    };
  });
}

function transactionDone(transaction: IDBTransaction): Promise<void> {
  return new Promise((resolve, reject) => {
    transaction.oncomplete = () => resolve();

    transaction.onerror = () => {
      reject(transaction.error || new Error('IndexedDB transaction failed.'));
    };

    transaction.onabort = () => {
      reject(transaction.error || new Error('IndexedDB transaction aborted.'));
    };
  });
}

export async function listBoothLocalAssets() {
  if (typeof window === 'undefined' || !window.indexedDB) {
    return [];
  }

  const db = await openBoothAssetsDb();

  try {
    const transaction = db.transaction(STORE_NAME, 'readonly');
    const store = transaction.objectStore(STORE_NAME);
    const assets = await requestToPromise<BoothLocalAssetRecord[]>(
      store.getAll(),
    );

    return assets.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  } finally {
    db.close();
  }
}

export async function getBoothLocalAssetsBySession(sessionId: string) {
  const assets = await listBoothLocalAssets();

  return assets.filter((asset) => asset.sessionId === sessionId);
}

export async function saveBoothLocalAsset(
  input: SaveBoothLocalAssetInput,
): Promise<BoothLocalAssetRecord> {
  const now = new Date().toISOString();

  const record: BoothLocalAssetRecord = {
    id: createId(input.kind),
    sessionId: input.sessionId,
    kind: input.kind,
    dataUrl: input.dataUrl,
    filename:
      input.filename ||
      buildBoothAssetFilename({
        sessionId: input.sessionId,
        kind: input.kind,
        slotId: input.slotId,
        outputId: input.outputId,
        renderMode: input.renderMode,
      }),
    mimeType: input.mimeType || inferMimeTypeFromDataUrl(input.dataUrl),
    sizeBytes: estimateDataUrlSizeBytes(input.dataUrl),
    createdAt: now,
    updatedAt: now,
    slotId: input.slotId,
    outputId: input.outputId,
    templateId: input.templateId,
    templateName: input.templateName,
    layoutId: input.layoutId,
    layoutName: input.layoutName,
    renderMode: input.renderMode,
    widthPx: input.widthPx,
    heightPx: input.heightPx,
    source: input.source,
    metadata: input.metadata,
  };

  const db = await openBoothAssetsDb();

  try {
    const transaction = db.transaction(STORE_NAME, 'readwrite');
    const store = transaction.objectStore(STORE_NAME);

    store.put(record);
    await transactionDone(transaction);

    return record;
  } finally {
    db.close();
  }
}

export async function deleteBoothLocalAsset(assetId: string) {
  const db = await openBoothAssetsDb();

  try {
    const transaction = db.transaction(STORE_NAME, 'readwrite');
    const store = transaction.objectStore(STORE_NAME);

    store.delete(assetId);
    await transactionDone(transaction);
  } finally {
    db.close();
  }
}

export async function deleteBoothLocalAssetsBySession(sessionId: string) {
  const assets = await getBoothLocalAssetsBySession(sessionId);
  const db = await openBoothAssetsDb();

  try {
    const transaction = db.transaction(STORE_NAME, 'readwrite');
    const store = transaction.objectStore(STORE_NAME);

    for (const asset of assets) {
      store.delete(asset.id);
    }

    await transactionDone(transaction);
  } finally {
    db.close();
  }
}

export async function clearBoothLocalAssets() {
  const db = await openBoothAssetsDb();

  try {
    const transaction = db.transaction(STORE_NAME, 'readwrite');
    const store = transaction.objectStore(STORE_NAME);

    store.clear();
    await transactionDone(transaction);
  } finally {
    db.close();
  }
}

export function summarizeBoothLocalAssets(
  assets: BoothLocalAssetRecord[],
): BoothLocalAssetSummary {
  return assets.reduce<BoothLocalAssetSummary>(
    (summary, asset) => {
      summary.totalAssets += 1;
      summary.totalSizeBytes += asset.sizeBytes || 0;

      if (asset.kind === 'raw_capture') {
        summary.rawCaptureCount += 1;
      }

      if (asset.kind === 'final_output') {
        summary.finalOutputCount += 1;
      }

      return summary;
    },
    {
      totalAssets: 0,
      rawCaptureCount: 0,
      finalOutputCount: 0,
      totalSizeBytes: 0,
    },
  );
}

export function formatAssetSize(sizeBytes: number) {
  if (sizeBytes < 1024) {
    return `${sizeBytes} B`;
  }

  if (sizeBytes < 1024 * 1024) {
    return `${(sizeBytes / 1024).toFixed(1)} KB`;
  }

  return `${(sizeBytes / 1024 / 1024).toFixed(1)} MB`;
}

export function downloadBoothLocalAsset(asset: BoothLocalAssetRecord) {
  const link = document.createElement('a');
  link.href = asset.dataUrl;
  link.download = asset.filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
}
TS

cat > apps/booth-ui/src/booth/BoothLocalAssetProvider.tsx <<'TSX'
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  clearBoothLocalAssets,
  deleteBoothLocalAsset,
  deleteBoothLocalAssetsBySession,
  getBoothLocalAssetsBySession,
  listBoothLocalAssets,
  saveBoothLocalAsset,
  summarizeBoothLocalAssets,
} from './booth-local-assets-db';
import type {
  BoothLocalAssetRecord,
  SaveBoothLocalAssetInput,
} from './booth-local-asset-types';

type BoothLocalAssetContextValue = {
  assets: BoothLocalAssetRecord[];
  isLoading: boolean;
  error: string;
  summary: ReturnType<typeof summarizeBoothLocalAssets>;
  refreshAssets: () => Promise<void>;
  saveAsset: (input: SaveBoothLocalAssetInput) => Promise<BoothLocalAssetRecord | null>;
  deleteAsset: (assetId: string) => Promise<void>;
  clearSessionAssets: (sessionId: string) => Promise<void>;
  clearAllAssets: () => Promise<void>;
  getSessionAssets: (sessionId: string) => Promise<BoothLocalAssetRecord[]>;
};

const BoothLocalAssetContext =
  createContext<BoothLocalAssetContextValue | null>(null);

type BoothLocalAssetProviderProps = {
  children: ReactNode;
};

export function BoothLocalAssetProvider({
  children,
}: BoothLocalAssetProviderProps) {
  const [assets, setAssets] = useState<BoothLocalAssetRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const refreshAssets = useCallback(async () => {
    setIsLoading(true);
    setError('');

    try {
      const nextAssets = await listBoothLocalAssets();
      setAssets(nextAssets);
    } catch (caughtError) {
      const message =
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to load local booth assets.';

      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshAssets();
  }, [refreshAssets]);

  const saveAsset = useCallback(
    async (input: SaveBoothLocalAssetInput) => {
      setError('');

      try {
        const asset = await saveBoothLocalAsset(input);
        await refreshAssets();
        return asset;
      } catch (caughtError) {
        const message =
          caughtError instanceof Error
            ? caughtError.message
            : 'Failed to save local booth asset.';

        setError(message);
        return null;
      }
    },
    [refreshAssets],
  );

  const deleteAsset = useCallback(
    async (assetId: string) => {
      setError('');

      try {
        await deleteBoothLocalAsset(assetId);
        await refreshAssets();
      } catch (caughtError) {
        const message =
          caughtError instanceof Error
            ? caughtError.message
            : 'Failed to delete local booth asset.';

        setError(message);
      }
    },
    [refreshAssets],
  );

  const clearSessionAssets = useCallback(
    async (sessionId: string) => {
      setError('');

      try {
        await deleteBoothLocalAssetsBySession(sessionId);
        await refreshAssets();
      } catch (caughtError) {
        const message =
          caughtError instanceof Error
            ? caughtError.message
            : 'Failed to clear local session assets.';

        setError(message);
      }
    },
    [refreshAssets],
  );

  const clearAllAssets = useCallback(async () => {
    setError('');

    try {
      await clearBoothLocalAssets();
      await refreshAssets();
    } catch (caughtError) {
      const message =
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to clear all local booth assets.';

      setError(message);
    }
  }, [refreshAssets]);

  const getSessionAssets = useCallback(async (sessionId: string) => {
    return getBoothLocalAssetsBySession(sessionId);
  }, []);

  const summary = useMemo(() => {
    return summarizeBoothLocalAssets(assets);
  }, [assets]);

  const value = useMemo<BoothLocalAssetContextValue>(() => {
    return {
      assets,
      isLoading,
      error,
      summary,
      refreshAssets,
      saveAsset,
      deleteAsset,
      clearSessionAssets,
      clearAllAssets,
      getSessionAssets,
    };
  }, [
    assets,
    isLoading,
    error,
    summary,
    refreshAssets,
    saveAsset,
    deleteAsset,
    clearSessionAssets,
    clearAllAssets,
    getSessionAssets,
  ]);

  return (
    <BoothLocalAssetContext.Provider value={value}>
      {children}
    </BoothLocalAssetContext.Provider>
  );
}

export function useBoothLocalAssets() {
  const context = useContext(BoothLocalAssetContext);

  if (!context) {
    throw new Error(
      'useBoothLocalAssets must be used inside BoothLocalAssetProvider',
    );
  }

  return context;
}
TSX

cat > apps/booth-ui/src/booth/BoothLocalAssetAutoSaver.tsx <<'TSX'
import { useEffect, useRef } from 'react';
import {
  useCameraRenderOutput,
  useCapturedFrames,
} from '../camera';
import { useBoothFlow } from './BoothFlowProvider';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';
import { useBoothLocalAssets } from './BoothLocalAssetProvider';

function isDataUrl(value: unknown): value is string {
  return typeof value === 'string' && value.startsWith('data:');
}

function getOutputDataUrl(output: unknown) {
  const value = output as {
    dataUrl?: unknown;
  };

  return isDataUrl(value.dataUrl) ? value.dataUrl : '';
}

function getOutputId(output: unknown) {
  const value = output as {
    id?: unknown;
  };

  return typeof value.id === 'string' ? value.id : '';
}

function getOutputNumber(output: unknown, key: string) {
  const value = output as Record<string, unknown>;
  const raw = value[key];

  return typeof raw === 'number' && Number.isFinite(raw) ? raw : undefined;
}

function getOutputString(output: unknown, key: string) {
  const value = output as Record<string, unknown>;
  const raw = value[key];

  return typeof raw === 'string' ? raw : undefined;
}

export function BoothLocalAssetAutoSaver() {
  const {
    session,
    currentStep,
    paymentStatus,
  } = useBoothFlow();

  const {
    photosBySlotId,
  } = useCapturedFrames();

  const {
    outputHistory,
  } = useCameraRenderOutput();

  const {
    saveAsset,
  } = useBoothLocalAssets();

  const {
    recordBoothEvent,
  } = useBoothLifecycleLogger();

  const savedRawKeysRef = useRef<Set<string>>(new Set());
  const savedOutputKeysRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    if (!session?.id) return;

    void (async () => {
      for (const [slotId, dataUrl] of Object.entries(photosBySlotId)) {
        if (!isDataUrl(dataUrl)) continue;

        const key = `${session.id}:raw:${slotId}:${dataUrl.length}`;

        if (savedRawKeysRef.current.has(key)) continue;

        savedRawKeysRef.current.add(key);

        const asset = await saveAsset({
          sessionId: session.id,
          kind: 'raw_capture',
          dataUrl,
          slotId,
          source: 'booth_auto_capture',
          metadata: {
            currentStep,
            paymentStatus,
          },
        });

        if (asset) {
          recordBoothEvent({
            type: 'debug_note',
            summary: `Raw capture saved locally for ${slotId}.`,
            sessionId: session.id,
            step: currentStep,
            paymentStatus,
            payload: {
              assetId: asset.id,
              slotId,
              filename: asset.filename,
              sizeBytes: asset.sizeBytes,
            },
          });
        }
      }
    })();
  }, [
    currentStep,
    paymentStatus,
    photosBySlotId,
    recordBoothEvent,
    saveAsset,
    session?.id,
  ]);

  useEffect(() => {
    if (!session?.id) return;

    void (async () => {
      for (const output of outputHistory) {
        const outputId = getOutputId(output);
        const dataUrl = getOutputDataUrl(output);

        if (!outputId || !dataUrl) continue;

        const key = `${session.id}:output:${outputId}`;

        if (savedOutputKeysRef.current.has(key)) continue;

        savedOutputKeysRef.current.add(key);

        const asset = await saveAsset({
          sessionId: session.id,
          kind: 'final_output',
          dataUrl,
          outputId,
          templateId: getOutputString(output, 'templateId'),
          templateName: getOutputString(output, 'templateName'),
          layoutId: getOutputString(output, 'layoutId'),
          layoutName: getOutputString(output, 'layoutName'),
          renderMode: getOutputString(output, 'renderMode'),
          widthPx: getOutputNumber(output, 'widthPx'),
          heightPx: getOutputNumber(output, 'heightPx'),
          source: 'booth_auto_render',
          metadata: {
            currentStep,
            paymentStatus,
            capturedSlotCount: getOutputNumber(output, 'capturedSlotCount'),
            totalSlotCount: getOutputNumber(output, 'totalSlotCount'),
          },
        });

        if (asset) {
          recordBoothEvent({
            type: 'debug_note',
            summary: 'Final output saved locally.',
            sessionId: session.id,
            step: currentStep,
            paymentStatus,
            payload: {
              assetId: asset.id,
              outputId,
              filename: asset.filename,
              sizeBytes: asset.sizeBytes,
            },
          });
        }
      }
    })();
  }, [
    currentStep,
    outputHistory,
    paymentStatus,
    recordBoothEvent,
    saveAsset,
    session?.id,
  ]);

  return null;
}
TSX

cat > apps/booth-ui/src/booth/BoothLocalAssetsPanel.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/booth/BoothRuntimeProviders.tsx <<'TSX'
import React, { type ReactNode } from 'react';
import {
  CameraCaptureGuideProvider,
  CameraPrintQueueProvider,
  CameraRenderOutputProvider,
  CapturedFramesProvider,
} from '../camera';
import { BoothFlowProvider } from './BoothFlowProvider';
import { BoothLifecycleAutoTracker } from './BoothLifecycleAutoTracker';
import { BoothLifecycleLoggerProvider } from './BoothLifecycleLoggerProvider';
import { BoothLocalAssetAutoSaver } from './BoothLocalAssetAutoSaver';
import { BoothLocalAssetProvider } from './BoothLocalAssetProvider';

type BoothRuntimeProvidersProps = {
  children: ReactNode;
};

export function BoothRuntimeProviders({
  children,
}: BoothRuntimeProvidersProps) {
  return (
    <BoothFlowProvider>
      <BoothLifecycleLoggerProvider>
        <BoothLocalAssetProvider>
          <CameraCaptureGuideProvider>
            <CapturedFramesProvider>
              <CameraRenderOutputProvider>
                <CameraPrintQueueProvider>
                  <BoothLifecycleAutoTracker />
                  <BoothLocalAssetAutoSaver />
                  {children}
                </CameraPrintQueueProvider>
              </CameraRenderOutputProvider>
            </CapturedFramesProvider>
          </CameraCaptureGuideProvider>
        </BoothLocalAssetProvider>
      </BoothLifecycleLoggerProvider>
    </BoothFlowProvider>
  );
}
TSX

INDEX="apps/booth-ui/src/booth/index.ts"
grep -q "booth-local-asset-types" "$INDEX" || cat >> "$INDEX" <<'TS'
export * from './booth-local-asset-types';
export * from './booth-local-assets-db';
export * from './BoothLocalAssetProvider';
export * from './BoothLocalAssetAutoSaver';
export * from './BoothLocalAssetsPanel';
TS

SCREEN="apps/booth-ui/src/booth/BoothCustomerScreen.tsx"

[ -f "$SCREEN" ] || {
  echo "ERROR: $SCREEN not found. Run 9B12-13 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/BoothCustomerScreen.tsx")
text = path.read_text()

import_line = "import { BoothLocalAssetsPanel } from './BoothLocalAssetsPanel';"

if import_line not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, import_line)
    text = "\n".join(lines) + "\n"

if "<BoothLocalAssetsPanel />" not in text:
    marker = """            <div className="mt-4">
              <BoothLifecycleDebugPanel />
            </div>"""

    replacement = marker + """

            <div className="mt-4">
              <BoothLocalAssetsPanel />
            </div>"""

    if marker not in text:
      raise SystemExit("Could not find lifecycle debug panel marker.")

    text = text.replace(marker, replacement, 1)

path.write_text(text)
print("PATCH:", path)
PY

DELIVERY="apps/booth-ui/src/booth/BoothDeliveryStep.tsx"

if [ -f "$DELIVERY" ]; then
python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/BoothDeliveryStep.tsx")
text = path.read_text()

import_line = "import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';"

if import_line not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, import_line)
    text = "\n".join(lines) + "\n"

text = text.replace(
    "  const { setStep, completeSession } = useBoothFlow();",
    "  const { session, setStep, completeSession } = useBoothFlow();",
    1,
)

if "recordBoothEvent" not in text:
    text = text.replace(
        """  const [copies, setCopies] = useState(1);
  const [isPrinting, setIsPrinting] = useState(false);
  const [message, setMessage] = useState('');""",
        """  const [copies, setCopies] = useState(1);
  const [isPrinting, setIsPrinting] = useState(false);
  const [message, setMessage] = useState('');

  const { recordBoothEvent } = useBoothLifecycleLogger();""",
        1,
    )

if "download_final_output" not in text:
    text = text.replace(
        """    downloadDataUrl({
      dataUrl: outputForDelivery.dataUrl,
      templateName: outputForDelivery.templateName,
      renderMode: outputForDelivery.renderMode,
    });

    setMessage('Final output downloaded.');""",
        """    downloadDataUrl({
      dataUrl: outputForDelivery.dataUrl,
      templateName: outputForDelivery.templateName,
      renderMode: outputForDelivery.renderMode,
    });

    recordBoothEvent({
      type: 'download_final_output',
      summary: 'Customer downloaded final output.',
      sessionId: session?.id,
      step: 'delivery',
      payload: {
        outputId: outputForDelivery.id,
        templateName: outputForDelivery.templateName,
        renderMode: outputForDelivery.renderMode,
      },
    });

    setMessage('Final output downloaded.');""",
        1,
    )

path.write_text(text)
print("PATCH:", path)
PY
fi

echo ""
echo "Relevant lines:"
grep -R "BoothLocalAsset\\|IndexedDB\\|download_final_output\\|Local Asset Registry" -n apps/booth-ui/src/booth || true

echo ""
echo "9B14-16 combined done."
