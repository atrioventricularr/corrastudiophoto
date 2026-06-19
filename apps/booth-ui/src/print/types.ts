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
