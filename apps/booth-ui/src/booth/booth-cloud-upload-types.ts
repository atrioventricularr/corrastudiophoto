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
