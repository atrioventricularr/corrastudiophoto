#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/booth/booth-cloud-upload-api.ts"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/booth/booth-cloud-upload-api.ts")
text = path.read_text()

pattern = re.compile(
r"""export function createBoothCloudUploadRecord\(input: \{
  asset: BoothLocalAssetRecord;
  result: BoothCloudUploadResult;
\}\): BoothCloudUploadRecord \{
[\s\S]*?
\}
$""",
re.MULTILINE
)

replacement = """export function createBoothCloudUploadRecord(input: {
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
"""

if not pattern.search(text):
    raise SystemExit("Could not find createBoothCloudUploadRecord block.")

text = pattern.sub(replacement, text)
path.write_text(text)

print("Fixed sourceAsset dataUrl omit in", path)
PY

echo ""
echo "Relevant lines:"
nl -ba "$FILE" | sed -n '70,115p'
