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
