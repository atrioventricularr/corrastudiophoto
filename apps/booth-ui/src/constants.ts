import { LayoutOptions, FrameTemplate, AdminSettings } from './types';

export const DEFAULT_LAYOUTS: LayoutOptions[] = [
  {
    id: '2_photo',
    name: 'Duo Photo Strip (2x1)',
    gridRows: 2,
    gridCols: 1,
    canvasWidth: 260,
    canvasHeight: 520,
    slots: 2,
    description: 'Classic vertical duo bookmark strip. Perfect for pairs!',
    aspectRatio: '1:2'
  },
  {
    id: '4_photo',
    name: 'Classic Grid (2x2)',
    gridRows: 2,
    gridCols: 2,
    canvasWidth: 380,
    canvasHeight: 380,
    slots: 4,
    description: 'The absolute standard. Symmetrical and gorgeous.',
    aspectRatio: '1:1'
  },
  {
    id: '6_photo',
    name: 'Triple Deluxe (3x2)',
    gridRows: 3,
    gridCols: 2,
    canvasWidth: 420,
    canvasHeight: 580,
    slots: 6,
    description: 'Six snaps for a full layout of wild poses and close-ups.',
    aspectRatio: '3:4'
  },
  {
    id: '8_photo',
    name: 'Bento Showcase (4x2)',
    gridRows: 4,
    gridCols: 2,
    canvasWidth: 440,
    canvasHeight: 680,
    slots: 8,
    description: 'Maximum variety layout resembling a classic sticker sheet grid.',
    aspectRatio: '2:3'
  }
];

export const DEFAULT_TEMPLATES: FrameTemplate[] = [
  {
    id: 'sweet_peach',
    name: '🍑 Sweet Milky Peach',
    bgColor: '#FFF5F5',
    borderColor: '#FFD1D1',
    pattern: 'cherry',
    stickerText: 'ときめき PEACHY',
    stickerColor: '#FF9494',
    textColor: '#8C3333'
  },
  {
    id: 'retro_soda',
    name: '🍹 Retro Soda Grid',
    bgColor: '#F0F9FF',
    borderColor: '#BAE6FD',
    pattern: 'grid',
    stickerText: 'SODA POP ★ 2000',
    stickerColor: '#38BDF8',
    textColor: '#0369A1'
  },
  {
    id: 'starry_arcade',
    name: '👾 Starry Neon Arcade',
    bgColor: '#FAF5FF',
    borderColor: '#E9D5FF',
    pattern: 'stars',
    stickerText: 'ARCADE DREAM -ぷりく-',
    stickerColor: '#C084FC',
    textColor: '#6B21A8'
  },
  {
    id: 'cream_cheese',
    name: '🧀 Warm Butter Toast',
    bgColor: '#FFFBEB',
    borderColor: '#FDE68A',
    pattern: 'dots',
    stickerText: 'NOSTALGIA CLASSIC',
    stickerColor: '#F59E0B',
    textColor: '#78350F'
  },
  {
    id: 'minimal_vintage',
    name: '📷 2000s Film Negative',
    bgColor: '#FAFAFA',
    borderColor: '#E4E4E7',
    pattern: 'vintage',
    stickerText: 'ANALOGUE SHUTTER',
    stickerColor: '#52525B',
    textColor: '#18181B'
  },
  {
    id: 'cherry_blossom',
    name: '🌸 Haru Sakura',
    bgColor: '#FFF1F2',
    borderColor: '#FECDD3',
    pattern: 'cherry',
    stickerText: '春の桜 • MEMORIES',
    stickerColor: '#FB7185',
    textColor: '#9F1239'
  }
];

export const INITIAL_ADMIN_SETTINGS: AdminSettings = {
  pricingIDR: 35000,
  sessionTimeoutSec: 120,
  countdownDurationSec: 5,
  paperRemainingCount: 154,
  ribbonRemainingPercent: 88,
  activeVouchers: ['NEOBOOT2026', 'HARUMUKU', 'CHIBIPRINT', 'FREEPASS'],
  qrisImageUrl: 'https://images.unsplash.com/photo-1595079676339-1534801ad6cf?auto=format&fit=crop&q=80&w=400',
  printerModelName: 'DNP RX1HS Dye-Sublimation',
  autoPrintEnabled: true,
  currencySymbol: 'Rp'
};

// Generates high aesthetic, retro Year-2000s cartoon/pastel mock images for previewing
export const SAMPLE_MOCK_PHOTOS = [
  { id: 'm1', url: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&q=80&w=500', name: 'Kawaii Shoto Girl' },
  { id: 'm2', url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=500', name: 'Retro Sunset Vibe' },
  { id: 'm3', url: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80&w=500', name: 'Fun Arcade Smile' },
  { id: 'm4', url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=500', name: 'Y2k Baggy Cap Style' },
  { id: 'm5', url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=500', name: 'Happy Peace Sign Pose' },
  { id: 'm6', url: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?auto=format&fit=crop&q=80&w=500', name: 'Tokyo Neon Coffee Shop' },
  { id: 'm7', url: 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&q=80&w=500', name: 'Soft Sunshine Hair' },
  { id: 'm8', url: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=500', name: 'Vintage Sunglasses Look' }
];
