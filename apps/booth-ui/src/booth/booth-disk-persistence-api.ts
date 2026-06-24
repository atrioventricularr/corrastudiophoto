import type {
  BoothDiskActionResult,
  BoothDiskFileRecord,
  BoothDiskListResult,
  BoothDiskSaveDataUrlInput,
  BoothDiskSaveTextInput,
  CorraDiskBridge,
} from './booth-disk-persistence-types';

export function getCorraDiskBridge(): CorraDiskBridge | undefined {
  if (typeof window === 'undefined') return undefined;
  return window.corraDisk;
}

export function isCorraDiskAvailable() {
  return Boolean(getCorraDiskBridge());
}

function unavailable(): never {
  throw new Error('Electron disk persistence bridge is not available. Run inside Corra Electron app.');
}

export async function getBoothDiskRoot(): Promise<BoothDiskActionResult> {
  const bridge = getCorraDiskBridge();
  if (!bridge) unavailable();
  return bridge.getRoot();
}

export async function openBoothDiskOutputFolder(sessionId?: string) {
  const bridge = getCorraDiskBridge();
  if (!bridge) unavailable();
  return bridge.openOutputFolder({ sessionId });
}

export async function saveBoothDataUrlToDisk(
  payload: BoothDiskSaveDataUrlInput,
): Promise<BoothDiskFileRecord> {
  const bridge = getCorraDiskBridge();
  if (!bridge) unavailable();
  return bridge.saveDataUrl(payload);
}

export async function saveBoothTextToDisk(
  payload: BoothDiskSaveTextInput,
): Promise<BoothDiskFileRecord> {
  const bridge = getCorraDiskBridge();
  if (!bridge) unavailable();
  return bridge.saveTextFile(payload);
}

export async function listBoothDiskFiles(sessionId?: string): Promise<BoothDiskListResult> {
  const bridge = getCorraDiskBridge();
  if (!bridge) unavailable();
  return bridge.listSessionFiles({ sessionId });
}

export async function deleteBoothDiskFile(relativePath: string) {
  const bridge = getCorraDiskBridge();
  if (!bridge) unavailable();
  return bridge.deleteFile({ relativePath });
}

export async function cleanupBoothDiskOlderThanDays(days: number) {
  const bridge = getCorraDiskBridge();
  if (!bridge) unavailable();
  return bridge.cleanupOlderThanDays({ days });
}
