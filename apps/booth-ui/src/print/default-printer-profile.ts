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
