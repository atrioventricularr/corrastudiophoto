export type LayoutType = '2_photo' | '4_photo' | '6_photo' | '8_photo';

export interface LayoutOptions {
  id: LayoutType;
  name: string;
  gridRows: number;
  gridCols: number;
  canvasWidth: number; // 16:9 ratio oriented relative units
  canvasHeight: number;
  slots: number;
  description: string;
  aspectRatio: string;
}

export interface FrameTemplate {
  id: string;
  name: string;
  bgColor: string;
  borderColor: string;
  pattern: 'solid' | 'grid' | 'dots' | 'stars' | 'cherry' | 'vintage';
  stickerText: string;
  stickerColor: string;
  textColor: string;
  isCustom?: boolean;
}

export interface AdminSettings {
  pricingIDR: number;
  sessionTimeoutSec: number;
  countdownDurationSec: number;
  paperRemainingCount: number;
  ribbonRemainingPercent: number;
  activeVouchers: string[];
  qrisImageUrl: string;
  printerModelName: string;
  autoPrintEnabled: boolean;
  currencySymbol: string;
}

export interface PhotoCapture {
  id: string;
  url: string; // real image URI or fallback lovely retro photo
  timestamp: string;
}

export type ApplicationScreen = 'welcome' | 'payment' | 'layout_select' | 'template_select' | 'camera_capture' | 'processing' | 'result' | 'admin';
