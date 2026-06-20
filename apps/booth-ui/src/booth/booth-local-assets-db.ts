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
