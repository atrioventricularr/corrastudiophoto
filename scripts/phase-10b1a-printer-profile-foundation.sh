#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10B1A - Printer Profile Foundation"
echo "========================================"

mkdir -p apps/booth-ui/src/print

cat > apps/booth-ui/src/print/types.ts <<'TS'
export type PrinterType = 'DNP' | 'INKJET' | 'GENERIC' | 'CUSTOM';

export type PrintOrientation = 'portrait' | 'landscape';

export type PrintMarginPx = {
  top: number;
  right: number;
  bottom: number;
  left: number;
};

export type PrintOffsetPx = {
  x: number;
  y: number;
};

export type PrinterProfile = {
  id: string;
  name: string;
  printerType: PrinterType;
  printerModel: string;

  paperName: string;
  paperWidthInch: number;
  paperHeightInch: number;
  orientation: PrintOrientation;
  dpi: number;

  borderless: boolean;
  rotateBeforePrint: boolean;

  marginPx: PrintMarginPx;
  offsetPx: PrintOffsetPx;
  scalePercent: number;

  notes?: string;
  updatedAt: string;
};

export type PrinterProfileContextValue = {
  printerProfile: PrinterProfile;
  updatePrinterProfile: (patch: Partial<PrinterProfile>) => void;
  resetPrinterProfile: () => void;
};
TS

cat > apps/booth-ui/src/print/default-printer-profile.ts <<'TS'
import type { PrinterProfile } from './types';

export const defaultPrinterProfile: PrinterProfile = {
  id: 'default-dnp-4r',
  name: 'DNP 4R Booth Default',
  printerType: 'DNP',
  printerModel: 'DNP DS-RX1HS',

  paperName: '4R / 4x6 inch',
  paperWidthInch: 4,
  paperHeightInch: 6,
  orientation: 'portrait',
  dpi: 300,

  borderless: true,
  rotateBeforePrint: false,

  marginPx: {
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
  },
  offsetPx: {
    x: 0,
    y: 0,
  },
  scalePercent: 100,

  notes:
    'Default DNP 4R profile. Adjust offset/scale if print result shifts.',
  updatedAt: new Date().toISOString(),
};
TS

cat > apps/booth-ui/src/print/local-printer-profile.ts <<'TS'
import { defaultPrinterProfile } from './default-printer-profile';
import type { PrinterProfile } from './types';

const STORAGE_KEY = 'corra.printerProfile.v1';

export function loadPrinterProfile(): PrinterProfile {
  if (typeof window === 'undefined') {
    return defaultPrinterProfile;
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultPrinterProfile;

    return {
      ...defaultPrinterProfile,
      ...(JSON.parse(raw) as Partial<PrinterProfile>),
    };
  } catch {
    return defaultPrinterProfile;
  }
}

export function savePrinterProfile(profile: PrinterProfile): void {
  if (typeof window === 'undefined') return;

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(profile));
}

export function clearPrinterProfile(): void {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(STORAGE_KEY);
}
TS

cat > apps/booth-ui/src/print/PrinterProfileProvider.tsx <<'TSX'
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { defaultPrinterProfile } from './default-printer-profile';
import {
  clearPrinterProfile,
  loadPrinterProfile,
  savePrinterProfile,
} from './local-printer-profile';
import type {
  PrinterProfile,
  PrinterProfileContextValue,
} from './types';

const PrinterProfileContext =
  createContext<PrinterProfileContextValue | null>(null);

type PrinterProfileProviderProps = {
  children: ReactNode;
};

export function PrinterProfileProvider({
  children,
}: PrinterProfileProviderProps) {
  const [printerProfile, setPrinterProfile] = useState<PrinterProfile>(() =>
    loadPrinterProfile(),
  );

  useEffect(() => {
    savePrinterProfile(printerProfile);
  }, [printerProfile]);

  const updatePrinterProfile = useCallback((patch: Partial<PrinterProfile>) => {
    setPrinterProfile((current) => ({
      ...current,
      ...patch,
      marginPx: {
        ...current.marginPx,
        ...(patch.marginPx || {}),
      },
      offsetPx: {
        ...current.offsetPx,
        ...(patch.offsetPx || {}),
      },
      updatedAt: new Date().toISOString(),
    }));
  }, []);

  const resetPrinterProfile = useCallback(() => {
    clearPrinterProfile();
    setPrinterProfile({
      ...defaultPrinterProfile,
      updatedAt: new Date().toISOString(),
    });
  }, []);

  const value = useMemo<PrinterProfileContextValue>(() => {
    return {
      printerProfile,
      updatePrinterProfile,
      resetPrinterProfile,
    };
  }, [printerProfile, updatePrinterProfile, resetPrinterProfile]);

  return (
    <PrinterProfileContext.Provider value={value}>
      {children}
    </PrinterProfileContext.Provider>
  );
}

export function usePrinterProfile(): PrinterProfileContextValue {
  const context = useContext(PrinterProfileContext);

  if (!context) {
    throw new Error(
      'usePrinterProfile must be used inside PrinterProfileProvider',
    );
  }

  return context;
}
TSX

cat > apps/booth-ui/src/print/index.ts <<'TS'
export * from './types';
export * from './default-printer-profile';
export * from './local-printer-profile';
export * from './PrinterProfileProvider';
TS

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/main.tsx")
text = path.read_text()

if "PrinterProfileProvider" not in text:
    lines = text.splitlines()
    insert_at = 0

    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1

    lines.insert(insert_at, "import { PrinterProfileProvider } from './print';")
    text = "\n".join(lines) + "\n"

if "<PrinterProfileProvider>" not in text:
    if "<SessionLifecycleProvider>" in text:
        text = text.replace(
            """<SessionLifecycleProvider>
            <ThemedBackground />
            <App />
          </SessionLifecycleProvider>""",
            """<SessionLifecycleProvider>
            <PrinterProfileProvider>
              <ThemedBackground />
              <App />
            </PrinterProfileProvider>
          </SessionLifecycleProvider>""",
        )
    else:
        text = text.replace(
            """<ThemedBackground />
          <App />""",
            """<PrinterProfileProvider>
            <ThemedBackground />
            <App />
          </PrinterProfileProvider>""",
        )

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Created print/printer profile foundation."
echo "Phase 10B1A completed."
