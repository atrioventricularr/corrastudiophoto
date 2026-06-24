import type { BoothCloudUploadRecord } from './booth-cloud-upload-types';

export type BoothSignedUrlRefreshResult = {
  ok: boolean;
  bucketName?: string;
  storagePath?: string;
  signedUrl?: string;
  signedUrlExpiresAt?: string;
  error?: string;
};

export function getRefreshBoothSignedUrlUrl() {
  return import.meta.env.VITE_REFRESH_BOOTH_SIGNED_URL_URL || '';
}

export async function refreshBoothSignedUrl(
  record: BoothCloudUploadRecord,
): Promise<BoothCloudUploadRecord> {
  const refreshUrl = getRefreshBoothSignedUrlUrl();

  if (!refreshUrl) {
    throw new Error(
      'VITE_REFRESH_BOOTH_SIGNED_URL_URL is not configured.',
    );
  }

  const response = await fetch(refreshUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      bucketName: record.bucketName,
      storagePath: record.storagePath,
      expiresInSeconds: 60 * 60 * 24 * 7,
    }),
  });

  const result = (await response.json()) as BoothSignedUrlRefreshResult;

  if (
    !response.ok ||
    !result.ok ||
    !result.signedUrl ||
    !result.signedUrlExpiresAt
  ) {
    throw new Error(result.error || 'Failed to refresh signed URL.');
  }

  return {
    ...record,
    signedUrl: result.signedUrl,
    signedUrlExpiresAt: result.signedUrlExpiresAt,
  };
}
