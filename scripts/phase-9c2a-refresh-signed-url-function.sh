#!/usr/bin/env bash
set -euo pipefail

mkdir -p supabase/functions/refresh-booth-signed-url

cat > supabase/functions/refresh-booth-signed-url/index.ts <<'TS'
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type RefreshRequest = {
  bucketName?: string;
  storagePath?: string;
  expiresInSeconds?: number;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function assertString(value: unknown, label: string) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${label} is required.`);
  }

  return value.trim();
}

serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return json({ ok: false, error: 'Method not allowed.' }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error('Missing Supabase Edge Function env.');
    }

    const payload = (await request.json()) as RefreshRequest;
    const bucketName = assertString(payload.bucketName, 'bucketName');
    const storagePath = assertString(payload.storagePath, 'storagePath');

    const expiresInSeconds = payload.expiresInSeconds || 60 * 60 * 24 * 7;
    const signedUrlExpiresAt = new Date(
      Date.now() + expiresInSeconds * 1000,
    ).toISOString();

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const result = await supabase.storage
      .from(bucketName)
      .createSignedUrl(storagePath, expiresInSeconds);

    if (result.error) throw result.error;

    await supabase
      .from('booth_cloud_asset_uploads')
      .update({
        signed_url: result.data.signedUrl,
        signed_url_expires_at: signedUrlExpiresAt,
      })
      .eq('bucket_name', bucketName)
      .eq('storage_path', storagePath);

    return json({
      ok: true,
      bucketName,
      storagePath,
      signedUrl: result.data.signedUrl,
      signedUrlExpiresAt,
    });
  } catch (error) {
    return json(
      {
        ok: false,
        error: error instanceof Error ? error.message : 'Unknown error.',
      },
      400,
    );
  }
});
TS

echo "9C2A refresh signed URL Edge Function created."
