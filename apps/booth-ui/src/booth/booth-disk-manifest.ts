import type { BoothDiskFileRecord } from './booth-disk-persistence-types';

export function buildBoothDiskManifest(input: {
  sessionId: string;
  records: BoothDiskFileRecord[];
  extra?: Record<string, unknown>;
}) {
  return {
    app: 'Corra Booth',
    format: 'corra-booth-session-manifest-v1',
    sessionId: input.sessionId,
    exportedAt: new Date().toISOString(),
    assetCount: input.records.length,
    assets: input.records,
    extra: input.extra || {},
  };
}

export function makeBoothManifestFilename(sessionId: string) {
  const safeSessionId = sessionId.replace(/[^a-zA-Z0-9._-]+/g, '-');
  return `corra-session-${safeSessionId || 'unknown'}-manifest.json`;
}
