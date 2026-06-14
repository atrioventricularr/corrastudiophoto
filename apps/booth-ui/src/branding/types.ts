export type CorraThemeId =
  | 'y2k'
  | 'wedding'
  | 'clean'
  | 'luxury'
  | 'corporate'
  | 'kids'
  | 'retro'
  | 'minimal';

export type CorraBackgroundType =
  | 'gradient'
  | 'solid'
  | 'image'
  | 'video';

export type CorraBackgroundFit = 'cover' | 'contain' | 'fill';

export type CorraThemePreset = {
  id: CorraThemeId;
  name: string;
  description: string;
  tokens: {
    primaryColor: string;
    secondaryColor: string;
    accentColor: string;
    backgroundColor: string;
    surfaceColor: string;
    textColor: string;
    mutedTextColor: string;
    borderColor: string;
    radius: string;
    fontHeading: string;
    fontBody: string;
  };
  defaultBackground: {
    type: CorraBackgroundType;
    value: string;
    fit: CorraBackgroundFit;
    opacity: number;
    overlayColor: string;
  };
};

export type CorraBrandConfig = {
  businessName: string;
  tagline: string;
  logoUrl: string | null;
  themeId: CorraThemeId;
  appearance: {
    backgroundType: CorraBackgroundType;
    backgroundValue: string;
    backgroundFit: CorraBackgroundFit;
    backgroundOpacity: number;
    overlayColor: string;
  };
};

export type CorraBrandThemeContextValue = {
  brandConfig: CorraBrandConfig;
  activeTheme: CorraThemePreset;
  setBrandConfig: (nextConfig: CorraBrandConfig) => void;
  updateBrandConfig: (patch: Partial<CorraBrandConfig>) => void;
  resetBrandConfig: () => void;
};
