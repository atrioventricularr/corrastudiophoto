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

  const { dataUrl, ...assetWithoutDataUrl } = input.asset;

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
      ...assetWithoutDataUrl,
      dataUrlLength: dataUrl.length,
    },
  };
}
