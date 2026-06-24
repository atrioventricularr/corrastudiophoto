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
