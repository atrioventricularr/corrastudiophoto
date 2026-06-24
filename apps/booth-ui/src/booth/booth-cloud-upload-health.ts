import type { BoothCloudUploadRecord } from './booth-cloud-upload-types';

export type BoothCloudUploadHealth = {
  total: number;
  valid: number;
  expiringSoon: number;
  expired: number;
  missingSignedUrl: number;
  nextExpiryAt?: string;
};

export function getCloudUploadRecordState(record: BoothCloudUploadRecord) {
  if (!record.signedUrl || !record.signedUrlExpiresAt) {
    return 'missing_signed_url';
  }

  const expiry = new Date(record.signedUrlExpiresAt).getTime();

  if (!Number.isFinite(expiry)) {
    return 'missing_signed_url';
  }

  const now = Date.now();
  const twelveHours = 1000 * 60 * 60 * 12;

  if (expiry <= now) {
    return 'expired';
  }

  if (expiry - now <= twelveHours) {
    return 'expiring_soon';
  }

  return 'valid';
}

export function summarizeCloudUploadHealth(
  records: BoothCloudUploadRecord[],
): BoothCloudUploadHealth {
  const summary: BoothCloudUploadHealth = {
    total: records.length,
    valid: 0,
    expiringSoon: 0,
    expired: 0,
    missingSignedUrl: 0,
  };

  const futureExpiries: number[] = [];

  for (const record of records) {
    const state = getCloudUploadRecordState(record);

    if (state === 'valid') summary.valid += 1;
    if (state === 'expiring_soon') summary.expiringSoon += 1;
    if (state === 'expired') summary.expired += 1;
    if (state === 'missing_signed_url') summary.missingSignedUrl += 1;

    const expiry = new Date(record.signedUrlExpiresAt).getTime();

    if (Number.isFinite(expiry) && expiry > Date.now()) {
      futureExpiries.push(expiry);
    }
  }

  if (futureExpiries.length > 0) {
    summary.nextExpiryAt = new Date(Math.min(...futureExpiries)).toISOString();
  }

  return summary;
}
