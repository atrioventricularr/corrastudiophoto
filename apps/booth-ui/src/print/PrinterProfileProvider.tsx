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
