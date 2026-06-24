import type {
  BoothHardwareActionResult,
  BoothHardwarePrinterListResult,
  BoothHardwarePrintPayload,
  BoothHardwareRuntimeInfo,
} from './booth-hardware-types';

declare global {
  interface Window {
    corraHardware?: {
      getRuntimeInfo: () => Promise<BoothHardwareRuntimeInfo>;
      listPrinters: () => Promise<BoothHardwarePrinterListResult>;
      printCurrentPage: (
        payload?: BoothHardwarePrintPayload,
      ) => Promise<BoothHardwareActionResult>;
      openUserData: () => Promise<BoothHardwareActionResult>;
      setFullscreen: (enabled: boolean) => Promise<BoothHardwareActionResult>;
      setKiosk: (enabled: boolean) => Promise<BoothHardwareActionResult>;
    };
  }
}

export function isCorraHardwareBridgeAvailable() {
  return typeof window !== 'undefined' && Boolean(window.corraHardware);
}

export async function getBoothHardwareRuntimeInfo() {
  if (!window.corraHardware) {
    return {
      ok: false,
      error: 'Electron hardware bridge is not available. Run inside Electron.',
    };
  }

  return window.corraHardware.getRuntimeInfo();
}

export async function listBoothHardwarePrinters() {
  if (!window.corraHardware) {
    return {
      ok: false,
      printers: [],
      error: 'Electron hardware bridge is not available. Run inside Electron.',
    };
  }

  return window.corraHardware.listPrinters();
}

export async function printBoothCurrentPage(payload?: BoothHardwarePrintPayload) {
  if (!window.corraHardware) {
    return {
      ok: false,
      error: 'Electron hardware bridge is not available. Run inside Electron.',
    };
  }

  return window.corraHardware.printCurrentPage(payload);
}

export async function openBoothUserDataPath() {
  if (!window.corraHardware) {
    return {
      ok: false,
      error: 'Electron hardware bridge is not available. Run inside Electron.',
    };
  }

  return window.corraHardware.openUserData();
}

export async function setBoothFullscreen(enabled: boolean) {
  if (!window.corraHardware) {
    return {
      ok: false,
      error: 'Electron hardware bridge is not available. Run inside Electron.',
    };
  }

  return window.corraHardware.setFullscreen(enabled);
}

export async function setBoothKiosk(enabled: boolean) {
  if (!window.corraHardware) {
    return {
      ok: false,
      error: 'Electron hardware bridge is not available. Run inside Electron.',
    };
  }

  return window.corraHardware.setKiosk(enabled);
}
