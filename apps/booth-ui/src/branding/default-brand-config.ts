import type { CorraBrandConfig } from './types';

export const DEFAULT_CORRA_BRAND_CONFIG: CorraBrandConfig = {
  businessName: 'Corra Studio',
  tagline: 'Self Service Photo Booth',
  logoUrl: null,
  themeId: 'y2k',
  appearance: {
    backgroundType: 'gradient',
    backgroundValue: 'radial-gradient(circle at top left, #FBCFE8, transparent 34%), radial-gradient(circle at bottom right, #FEF3C7, transparent 32%), #FFF1F7',
    backgroundFit: 'cover',
    backgroundOpacity: 1,
    overlayColor: 'rgba(255,255,255,0)',
  },
};
