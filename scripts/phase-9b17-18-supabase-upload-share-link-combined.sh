#!/usr/bin/env bash
set -euo pipefail

echo "================================================="
echo " Phase 9B17-18 - Supabase Upload + Share Link"
echo "================================================="

mkdir -p apps/booth-ui/src/booth
mkdir -p supabase/functions/upload-booth-asset
mkdir -p supabase/migrations

cat > supabase/migrations/022_booth_cloud_asset_uploads.sql <<'SQL'
create table if not exists public.booth_cloud_asset_uploads (
  id uuid primary key default gen_random_uuid(),
  local_asset_id text,
  session_id text not null,
  asset_kind text not null check (asset_kind in ('raw_capture', 'final_output')),
  bucket_name text not null,
  storage_path text not null,
  filename text not null,
  mime_type text not null default 'image/png',
  size_bytes bigint not null default 0,
  signed_url text,
  signed_url_expires_at timestamptz,
  slot_id text,
  output_id text,
  template_id text,
  template_name text,
  layout_id text,
  layout_name text,
  render_mode text,
  width_px integer,
  height_px integer,
  source text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists booth_cloud_asset_uploads_session_id_idx
  on public.booth_cloud_asset_uploads(session_id);

create index if not exists booth_cloud_asset_uploads_asset_kind_idx
  on public.booth_cloud_asset_uploads(asset_kind);

create index if not exists booth_cloud_asset_uploads_created_at_idx
  on public.booth_cloud_asset_uploads(created_at desc);

alter table public.booth_cloud_asset_uploads enable row level security;

drop policy if exists "Service role can manage booth cloud asset uploads"
  on public.booth_cloud_asset_uploads;

create policy "Service role can manage booth cloud asset uploads"
  on public.booth_cloud_asset_uploads
  for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');
SQL

cat > supabase/functions/upload-booth-asset/index.ts <<'TS'
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type UploadAssetRequest = {
  localAssetId?: string;
  sessionId?: string;
  kind?: 'raw_capture' | 'final_output';
  dataUrl?: string;
  filename?: string;
  mimeType?: string;
  sizeBytes?: number;
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

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function sanitizePathPart(value: string) {
  return value
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/(^-+|-+$)/g, '')
    .slice(0, 120);
}

function ensurePngFilename(filename: string) {
  const safeName = sanitizePathPart(filename || 'corra-booth-output.png');

  if (safeName.toLowerCase().endsWith('.png')) {
    return safeName;
  }

  return `${safeName}.png`;
}

function decodeDataUrl(dataUrl: string) {
  const match = dataUrl.match(/^data:([^;,]+)?(;base64)?,(.*)$/);

  if (!match) {
    throw new Error('Invalid dataUrl format.');
  }

  const mimeType = match[1] || 'image/png';
  const isBase64 = Boolean(match[2]);
  const payload = match[3] || '';

  if (!payload) {
    throw new Error('Empty dataUrl payload.');
  }

  if (isBase64) {
    const binary = atob(payload);
    const bytes = new Uint8Array(binary.length);

    for (let index = 0; index < binary.length; index += 1) {
      bytes[index] = binary.charCodeAt(index);
    }

    return {
      bytes,
      mimeType,
      sizeBytes: bytes.byteLength,
    };
  }

  const decoded = decodeURIComponent(payload);
  const bytes = new TextEncoder().encode(decoded);

  return {
    bytes,
    mimeType,
    sizeBytes: bytes.byteLength,
  };
}

function assertString(value: unknown, label: string) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${label} is required.`);
  }

  return value.trim();
}

function getBucketName(kind: UploadAssetRequest['kind']) {
  if (kind === 'raw_capture') return 'raw-photos';
  if (kind === 'final_output') return 'final-frames';

  throw new Error('Invalid asset kind.');
}

serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    });
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      {
        ok: false,
        error: 'Method not allowed.',
      },
      405,
    );
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error(
        'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in Edge Function environment.',
      );
    }

    const payload = (await request.json()) as UploadAssetRequest;

    const sessionId = assertString(payload.sessionId, 'sessionId');
    const dataUrl = assertString(payload.dataUrl, 'dataUrl');
    const kind = payload.kind;

    if (kind !== 'raw_capture' && kind !== 'final_output') {
      throw new Error('kind must be raw_capture or final_output.');
    }

    const decoded = decodeDataUrl(dataUrl);
    const bucketName = getBucketName(kind);
    const filename = ensurePngFilename(
      payload.filename ||
        `${kind}-${new Date().toISOString().replace(/[:.]/g, '-')}.png`,
    );

    const safeSessionId = sanitizePathPart(sessionId);
    const datePart = new Date().toISOString().slice(0, 10);
    const storagePath = [
      'booth',
      datePart,
      safeSessionId,
      kind,
      filename,
    ].join('/');

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
      },
    });

    const uploadResult = await supabase.storage
      .from(bucketName)
      .upload(storagePath, decoded.bytes, {
        contentType: payload.mimeType || decoded.mimeType || 'image/png',
        upsert: true,
      });

    if (uploadResult.error) {
      throw uploadResult.error;
    }

    const signedUrlExpiresInSeconds = 60 * 60 * 24 * 7;
    const signedUrlExpiresAt = new Date(
      Date.now() + signedUrlExpiresInSeconds * 1000,
    ).toISOString();

    const signedUrlResult = await supabase.storage
      .from(bucketName)
      .createSignedUrl(storagePath, signedUrlExpiresInSeconds);

    if (signedUrlResult.error) {
      throw signedUrlResult.error;
    }

    let databaseRecord = null;
    const insertResult = await supabase
      .from('booth_cloud_asset_uploads')
      .insert({
        local_asset_id: payload.localAssetId,
        session_id: sessionId,
        asset_kind: kind,
        bucket_name: bucketName,
        storage_path: storagePath,
        filename,
        mime_type: payload.mimeType || decoded.mimeType || 'image/png',
        size_bytes: payload.sizeBytes || decoded.sizeBytes,
        signed_url: signedUrlResult.data.signedUrl,
        signed_url_expires_at: signedUrlExpiresAt,
        slot_id: payload.slotId,
        output_id: payload.outputId,
        template_id: payload.templateId,
        template_name: payload.templateName,
        layout_id: payload.layoutId,
        layout_name: payload.layoutName,
        render_mode: payload.renderMode,
        width_px: payload.widthPx,
        height_px: payload.heightPx,
        source: payload.source,
        metadata: payload.metadata || {},
      })
      .select('*')
      .single();

    if (!insertResult.error) {
      databaseRecord = insertResult.data;
    }

    return jsonResponse({
      ok: true,
      localAssetId: payload.localAssetId,
      sessionId,
      kind,
      bucketName,
      storagePath,
      filename,
      mimeType: payload.mimeType || decoded.mimeType || 'image/png',
      sizeBytes: payload.sizeBytes || decoded.sizeBytes,
      signedUrl: signedUrlResult.data.signedUrl,
      signedUrlExpiresAt,
      databaseRecord,
      databaseWarning: insertResult.error
        ? insertResult.error.message
        : undefined,
    });
  } catch (error) {
    return jsonResponse(
      {
        ok: false,
        error: error instanceof Error ? error.message : 'Unknown upload error.',
      },
      400,
    );
  }
});
TS

cat > apps/booth-ui/src/booth/booth-cloud-upload-types.ts <<'TS'
import type {
  BoothLocalAssetKind,
  BoothLocalAssetRecord,
} from './booth-local-asset-types';

export type BoothCloudUploadResult = {
  ok: boolean;
  localAssetId?: string;
  sessionId?: string;
  kind?: BoothLocalAssetKind;
  bucketName?: string;
  storagePath?: string;
  filename?: string;
  mimeType?: string;
  sizeBytes?: number;
  signedUrl?: string;
  signedUrlExpiresAt?: string;
  databaseRecord?: unknown;
  databaseWarning?: string;
  error?: string;
};

export type BoothCloudUploadRecord = {
  id: string;
  localAssetId: string;
  sessionId: string;
  kind: BoothLocalAssetKind;
  filename: string;
  uploadedAt: string;
  bucketName: string;
  storagePath: string;
  signedUrl: string;
  signedUrlExpiresAt: string;
  sizeBytes: number;
  sourceAsset: Omit<BoothLocalAssetRecord, 'dataUrl'> & {
    dataUrlLength: number;
  };
};
TS

cat > apps/booth-ui/src/booth/booth-cloud-upload-storage.ts <<'TS'
import type {
  BoothCloudUploadRecord,
} from './booth-cloud-upload-types';

const BOOTH_CLOUD_UPLOAD_RECORDS_KEY =
  'corra.booth.cloud.upload.records.v1';

const MAX_UPLOAD_RECORDS = 250;

export function loadBoothCloudUploadRecords(): BoothCloudUploadRecord[] {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(BOOTH_CLOUD_UPLOAD_RECORDS_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed.filter((record) => {
      return (
        record &&
        typeof record.id === 'string' &&
        typeof record.localAssetId === 'string' &&
        typeof record.sessionId === 'string' &&
        typeof record.signedUrl === 'string'
      );
    });
  } catch (error) {
    console.warn('[Corra Booth] Failed to load cloud upload records:', error);
    return [];
  }
}

export function saveBoothCloudUploadRecords(
  records: BoothCloudUploadRecord[],
) {
  if (typeof window === 'undefined') return;

  const limitedRecords = records.slice(-MAX_UPLOAD_RECORDS);

  window.localStorage.setItem(
    BOOTH_CLOUD_UPLOAD_RECORDS_KEY,
    JSON.stringify(limitedRecords),
  );
}

export function clearBoothCloudUploadRecords() {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(BOOTH_CLOUD_UPLOAD_RECORDS_KEY);
}
TS

cat > apps/booth-ui/src/booth/booth-cloud-upload-api.ts <<'TS'
import type {
  BoothLocalAssetRecord,
} from './booth-local-asset-types';
import type {
  BoothCloudUploadRecord,
  BoothCloudUploadResult,
} from './booth-cloud-upload-types';

export function getBoothUploadAssetUrl() {
  return import.meta.env.VITE_UPLOAD_BOOTH_ASSET_URL || '';
}

function createUploadRecordId() {
  if (
    typeof window !== 'undefined' &&
    window.crypto &&
    typeof window.crypto.randomUUID === 'function'
  ) {
    return `cloud-upload-${window.crypto.randomUUID()}`;
  }

  return `cloud-upload-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export async function uploadBoothLocalAssetToCloud(
  asset: BoothLocalAssetRecord,
): Promise<BoothCloudUploadResult> {
  const uploadUrl = getBoothUploadAssetUrl();

  if (!uploadUrl) {
    throw new Error(
      'VITE_UPLOAD_BOOTH_ASSET_URL is not configured. Deploy upload-booth-asset first.',
    );
  }

  const response = await fetch(uploadUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      localAssetId: asset.id,
      sessionId: asset.sessionId,
      kind: asset.kind,
      dataUrl: asset.dataUrl,
      filename: asset.filename,
      mimeType: asset.mimeType,
      sizeBytes: asset.sizeBytes,
      slotId: asset.slotId,
      outputId: asset.outputId,
      templateId: asset.templateId,
      templateName: asset.templateName,
      layoutId: asset.layoutId,
      layoutName: asset.layoutName,
      renderMode: asset.renderMode,
      widthPx: asset.widthPx,
      heightPx: asset.heightPx,
      source: asset.source,
      metadata: asset.metadata,
    }),
  });

  const result = (await response.json()) as BoothCloudUploadResult;

  if (!response.ok || !result.ok) {
    throw new Error(result.error || 'Failed to upload booth local asset.');
  }

  return result;
}

export function createBoothCloudUploadRecord(input: {
  asset: BoothLocalAssetRecord;
  result: BoothCloudUploadResult;
}): BoothCloudUploadRecord {
  if (!input.result.bucketName || !input.result.storagePath) {
    throw new Error('Upload result missing bucketName or storagePath.');
  }

  if (!input.result.signedUrl || !input.result.signedUrlExpiresAt) {
    throw new Error('Upload result missing signed URL.');
  }

  return {
    id: createUploadRecordId(),
    localAssetId: input.asset.id,
    sessionId: input.asset.sessionId,
    kind: input.asset.kind,
    filename: input.result.filename || input.asset.filename,
    uploadedAt: new Date().toISOString(),
    bucketName: input.result.bucketName,
    storagePath: input.result.storagePath,
    signedUrl: input.result.signedUrl,
    signedUrlExpiresAt: input.result.signedUrlExpiresAt,
    sizeBytes: input.result.sizeBytes || input.asset.sizeBytes,
    sourceAsset: {
      ...input.asset,
      dataUrlLength: input.asset.dataUrl.length,
      dataUrl: undefined as never,
    },
  };
}
TS

cat > apps/booth-ui/src/booth/BoothCloudUploadPanel.tsx <<'TSX'
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
TSX

INDEX="apps/booth-ui/src/booth/index.ts"
grep -q "booth-cloud-upload-types" "$INDEX" || cat >> "$INDEX" <<'TS'
export * from './booth-cloud-upload-types';
export * from './booth-cloud-upload-storage';
export * from './booth-cloud-upload-api';
export * from './BoothCloudUploadPanel';
TS

SCREEN="apps/booth-ui/src/booth/BoothCustomerScreen.tsx"

[ -f "$SCREEN" ] || {
  echo "ERROR: $SCREEN not found. Run 9B14-16 first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/booth/BoothCustomerScreen.tsx")
text = path.read_text()

import_line = "import { BoothCloudUploadPanel } from './BoothCloudUploadPanel';"

if import_line not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, import_line)
    text = "\n".join(lines) + "\n"

if "<BoothCloudUploadPanel />" not in text:
    marker = """            <div className="mt-4">
              <BoothLocalAssetsPanel />
            </div>"""

    replacement = marker + """

            <div className="mt-4">
              <BoothCloudUploadPanel />
            </div>"""

    if marker not in text:
      raise SystemExit("Could not find local assets panel marker.")

    text = text.replace(marker, replacement, 1)

path.write_text(text)
print("PATCH:", path)
PY

ENV_FILE="apps/booth-ui/.env.local"
mkdir -p apps/booth-ui

if [ ! -f "$ENV_FILE" ]; then
  touch "$ENV_FILE"
fi

if ! grep -q "^VITE_UPLOAD_BOOTH_ASSET_URL=" "$ENV_FILE"; then
  cat >> "$ENV_FILE" <<'ENV'

VITE_UPLOAD_BOOTH_ASSET_URL=https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/upload-booth-asset
ENV
fi

echo ""
echo "Relevant lines:"
grep -R "BoothCloudUpload\\|upload-booth-asset\\|VITE_UPLOAD_BOOTH_ASSET_URL\\|Cloud Upload" -n apps/booth-ui/src/booth supabase/functions/upload-booth-asset "$ENV_FILE" || true

echo ""
echo "9B17-18 combined files created."
echo ""
echo "NEXT DEPLOY STEPS:"
echo "1) supabase db push"
echo "2) supabase functions deploy upload-booth-asset --no-verify-jwt"
echo "3) pnpm --filter @corra/booth-ui exec tsc --noEmit --pretty false"
