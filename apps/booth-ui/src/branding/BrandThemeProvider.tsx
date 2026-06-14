import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { DEFAULT_CORRA_BRAND_CONFIG } from './default-brand-config';
import { getThemePreset } from './theme-presets';
import {
  clearLocalBrandConfig,
  loadLocalBrandConfig,
  saveLocalBrandConfig,
} from './local-brand-config';
import type { CorraBrandConfig, CorraBrandThemeContextValue } from './types';

const BrandThemeContext = createContext<CorraBrandThemeContextValue | null>(null);

type BrandThemeProviderProps = {
  children: ReactNode;
};

function applyThemeVariables(config: CorraBrandConfig): void {
  if (typeof document === 'undefined') {
    return;
  }

  const theme = getThemePreset(config.themeId);
  const root = document.documentElement;

  root.style.setProperty('--corra-primary', theme.tokens.primaryColor);
  root.style.setProperty('--corra-secondary', theme.tokens.secondaryColor);
  root.style.setProperty('--corra-accent', theme.tokens.accentColor);
  root.style.setProperty('--corra-bg', theme.tokens.backgroundColor);
  root.style.setProperty('--corra-surface', theme.tokens.surfaceColor);
  root.style.setProperty('--corra-text', theme.tokens.textColor);
  root.style.setProperty('--corra-muted', theme.tokens.mutedTextColor);
  root.style.setProperty('--corra-border', theme.tokens.borderColor);
  root.style.setProperty('--corra-radius', theme.tokens.radius);
  root.style.setProperty('--corra-font-heading', theme.tokens.fontHeading);
  root.style.setProperty('--corra-font-body', theme.tokens.fontBody);

  root.dataset.corraTheme = config.themeId;
  root.dataset.corraBrand = config.businessName;
}

export function BrandThemeProvider({ children }: BrandThemeProviderProps) {
  const [brandConfig, setBrandConfigState] = useState<CorraBrandConfig>(() =>
    loadLocalBrandConfig(),
  );

  const activeTheme = useMemo(
    () => getThemePreset(brandConfig.themeId),
    [brandConfig.themeId],
  );

  useEffect(() => {
    applyThemeVariables(brandConfig);
    saveLocalBrandConfig(brandConfig);
  }, [brandConfig]);

  const value = useMemo<CorraBrandThemeContextValue>(() => {
    return {
      brandConfig,
      activeTheme,
      setBrandConfig: setBrandConfigState,
      updateBrandConfig: (patch) => {
        setBrandConfigState((current) => ({
          ...current,
          ...patch,
          appearance: {
            ...current.appearance,
            ...(patch.appearance || {}),
          },
        }));
      },
      resetBrandConfig: () => {
        clearLocalBrandConfig();
        setBrandConfigState(DEFAULT_CORRA_BRAND_CONFIG);
      },
    };
  }, [activeTheme, brandConfig]);

  return (
    <BrandThemeContext.Provider value={value}>
      {children}
    </BrandThemeContext.Provider>
  );
}

export function useBrandTheme(): CorraBrandThemeContextValue {
  const context = useContext(BrandThemeContext);

  if (!context) {
    throw new Error('useBrandTheme must be used inside BrandThemeProvider');
  }

  return context;
}
