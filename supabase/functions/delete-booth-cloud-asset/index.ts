import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

type DeleteRequest = {
  bucketName?: string;
  storagePath?: string;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
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
      throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.');
    }

    const payload = (await request.json()) as DeleteRequest;
    const bucketName = assertString(payload.bucketName, 'bucketName');
    const storagePath = assertString(payload.storagePath, 'storagePath');

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    // Delete from storage
    const removeResult = await supabase.storage
      .from(bucketName)
      .remove([storagePath]);

    if (removeResult.error) throw removeResult.error;

    // Delete from database
    await supabase
      .from('booth_cloud_asset_uploads')
      .delete()
      .eq('bucket_name', bucketName)
      .eq('storage_path', storagePath);

    return json({
      ok: true,
      bucketName,
      storagePath,
      message: 'Asset deleted successfully',
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
