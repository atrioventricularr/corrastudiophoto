import {
  getBoothHardwareRuntimeInfo,
  isCorraHardwareBridgeAvailable,
  listBoothHardwarePrinters,
} from './booth-hardware-api';
import { loadBoothCloudUploadRecords } from './booth-cloud-upload-storage';
import { loadBoothDiskRecords } from './booth-disk-storage';
import { loadBoothHardwareTestRecords } from './booth-hardware-test-storage';
import { upsertBoothReleaseCheckRecord } from './booth-release-readiness-storage';

function getPaymentConfiguredMessage() {
  try {
    const raw = window.localStorage.getItem('corra.payment.settings.v1');
    if (!raw) return 'Payment settings not found yet.';
    return 'Payment settings found in localStorage.';
  } catch {
    return 'Unable to inspect payment settings.';
  }
}

export async function runBoothReleaseDiagnostics() {
  const results: Array<{ label: string; ok: boolean; message: string }> = [];
  const hardwareBridge = isCorraHardwareBridgeAvailable();

  upsertBoothReleaseCheckRecord({
    label: 'Electron runtime opens',
    category: 'electron',
    status: hardwareBridge ? 'passed' : 'warning',
    message: hardwareBridge
      ? 'Electron hardware bridge is available.'
      : 'Hardware bridge unavailable in browser. Test inside Electron.',
  });

  results.push({
    label: 'Electron runtime opens',
    ok: hardwareBridge,
    message: hardwareBridge ? 'Bridge available.' : 'Bridge unavailable.',
  });

  if (hardwareBridge) {
    const runtime = await getBoothHardwareRuntimeInfo();
    results.push({
      label: 'Runtime info',
      ok: runtime.ok,
      message: runtime.ok ? 'Runtime info loaded.' : runtime.error || 'Runtime failed.',
    });

    const printers = await listBoothHardwarePrinters();
    upsertBoothReleaseCheckRecord({
      label: 'Printer detected',
      category: 'hardware',
      status: printers.ok && printers.printers.length > 0 ? 'passed' : 'warning',
      message:
        printers.ok && printers.printers.length > 0
          ? `${printers.printers.length} printer(s) detected.`
          : printers.error || 'No printer detected.',
    });
  }

  const paymentMessage = getPaymentConfiguredMessage();
  upsertBoothReleaseCheckRecord({
    label: 'Payment method configured',
    category: 'payment',
    status: paymentMessage.includes('found') ? 'passed' : 'warning',
    message: paymentMessage,
  });

  const cloudRecords = loadBoothCloudUploadRecords();
  upsertBoothReleaseCheckRecord({
    label: 'Cloud upload configured',
    category: 'cloud',
    status: import.meta.env.VITE_UPLOAD_BOOTH_ASSET_URL ? 'passed' : 'warning',
    message:
      cloudRecords.length > 0
        ? `${cloudRecords.length} cloud upload record(s) found.`
        : 'Cloud env checked; no upload record yet.',
  });

  const diskRecords = loadBoothDiskRecords();
  upsertBoothReleaseCheckRecord({
    label: 'Disk persistence works',
    category: 'disk',
    status: diskRecords.length > 0 ? 'passed' : 'warning',
    message:
      diskRecords.length > 0
        ? `${diskRecords.length} disk record(s) found.`
        : 'No disk record yet. Save an output inside Electron.',
  });

  const hardwareRecords = loadBoothHardwareTestRecords();
  const cameraPassed = hardwareRecords.some(
    (record) => record.label === 'Camera discovery' && record.status === 'passed',
  );
  const kioskPassed = hardwareRecords.some(
    (record) => record.label === 'Kiosk on' && record.status === 'passed',
  );

  upsertBoothReleaseCheckRecord({
    label: 'Camera detected',
    category: 'hardware',
    status: cameraPassed ? 'passed' : 'warning',
    message: cameraPassed ? 'Camera test passed.' : 'Run camera hardware test.',
  });

  upsertBoothReleaseCheckRecord({
    label: 'Kiosk mode tested',
    category: 'kiosk',
    status: kioskPassed ? 'passed' : 'warning',
    message: kioskPassed ? 'Kiosk test passed.' : 'Run kiosk hardware test.',
  });

  return results;
}
