#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Corra Booth - Phase 7C1 Brand Theme Background Foundation"
echo "========================================"

fail() {
  echo ""
  echo "ERROR: $1"
  echo ""
  exit 1
}

write_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"
  cat > "$file_path"
  echo "WRITE file: $file_path"
}

[ -f "package.json" ] || fail "Run this from repo root."
[ -f "apps/booth-ui/src/main.tsx" ] || fail "apps/booth-ui/src/main.tsx not found."
[ -f "apps/booth-ui/src/index.css" ] || fail "apps/booth-ui/src/index.css not found."

echo ""
echo "Updating .gitignore for local Electron vendor binaries..."

touch .gitignore

grep -q "vendor/electron/" .gitignore || cat >> .gitignore <<'GITIGNORE'

# Local manual Electron binary/vendor downloads
vendor/electron/
vendor/electron*.zip
vendor/electron-v*/
GITIGNORE

echo ""
echo "Writing brand/theme types..."

write_file "apps/booth-ui/src/branding/types.ts" <<'TS'
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
TS

echo ""
echo "Writing theme presets..."

write_file "apps/booth-ui/src/branding/theme-presets.ts" <<'TS'
import type { CorraThemeId, CorraThemePreset } from './types';

export const CORRA_THEME_PRESETS: Record<CorraThemeId, CorraThemePreset> = {
  y2k: {
    id: 'y2k',
    name: 'Y2K Pop',
    description: 'Pink, playful, retro digital booth look.',
    tokens: {
      primaryColor: '#EC4899',
      secondaryColor: '#F9A8D4',
      accentColor: '#FACC15',
      backgroundColor: '#FFF1F7',
      surfaceColor: '#FFFFFF',
      textColor: '#1C1917',
      mutedTextColor: '#78716C',
      borderColor: '#FBCFE8',
      radius: '2rem',
      fontHeading: 'Playfair Display, Georgia, serif',
      fontBody: 'Outfit, Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'gradient',
      value: 'radial-gradient(circle at top left, #FBCFE8, transparent 34%), radial-gradient(circle at bottom right, #FEF3C7, transparent 32%), #FFF1F7',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(255,255,255,0)',
    },
  },
  wedding: {
    id: 'wedding',
    name: 'Wedding',
    description: 'Soft cream, gold, romantic wedding booth.',
    tokens: {
      primaryColor: '#B88A44',
      secondaryColor: '#F5E6C8',
      accentColor: '#D6A95C',
      backgroundColor: '#FFF8EC',
      surfaceColor: '#FFFCF6',
      textColor: '#2C2117',
      mutedTextColor: '#8A7560',
      borderColor: '#EAD8B8',
      radius: '1.75rem',
      fontHeading: 'Playfair Display, Georgia, serif',
      fontBody: 'Outfit, Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'gradient',
      value: 'linear-gradient(135deg, #FFF8EC 0%, #F7E7C6 52%, #FFFDF8 100%)',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(255,255,255,0.1)',
    },
  },
  clean: {
    id: 'clean',
    name: 'Clean',
    description: 'Neutral, bright, simple modern interface.',
    tokens: {
      primaryColor: '#111827',
      secondaryColor: '#E5E7EB',
      accentColor: '#2563EB',
      backgroundColor: '#F8FAFC',
      surfaceColor: '#FFFFFF',
      textColor: '#111827',
      mutedTextColor: '#64748B',
      borderColor: '#E2E8F0',
      radius: '1.25rem',
      fontHeading: 'Inter, system-ui, sans-serif',
      fontBody: 'Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'solid',
      value: '#F8FAFC',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(255,255,255,0)',
    },
  },
  luxury: {
    id: 'luxury',
    name: 'Luxury',
    description: 'Black, champagne, premium self-photo studio.',
    tokens: {
      primaryColor: '#D4AF37',
      secondaryColor: '#2A2118',
      accentColor: '#F3D37A',
      backgroundColor: '#090909',
      surfaceColor: '#161616',
      textColor: '#FFF7E6',
      mutedTextColor: '#C7B99B',
      borderColor: '#3D3324',
      radius: '1.5rem',
      fontHeading: 'Playfair Display, Georgia, serif',
      fontBody: 'Outfit, Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'gradient',
      value: 'radial-gradient(circle at top, #2A2118, transparent 40%), #090909',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(0,0,0,0.2)',
    },
  },
  corporate: {
    id: 'corporate',
    name: 'Corporate',
    description: 'Professional event booth for brands and offices.',
    tokens: {
      primaryColor: '#0F766E',
      secondaryColor: '#CCFBF1',
      accentColor: '#14B8A6',
      backgroundColor: '#F0FDFA',
      surfaceColor: '#FFFFFF',
      textColor: '#134E4A',
      mutedTextColor: '#5F7F7A',
      borderColor: '#99F6E4',
      radius: '1.25rem',
      fontHeading: 'Inter, system-ui, sans-serif',
      fontBody: 'Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'solid',
      value: '#F0FDFA',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(255,255,255,0)',
    },
  },
  kids: {
    id: 'kids',
    name: 'Kids Party',
    description: 'Bright colorful booth for birthday and family events.',
    tokens: {
      primaryColor: '#8B5CF6',
      secondaryColor: '#FDE68A',
      accentColor: '#FB7185',
      backgroundColor: '#FEF3C7',
      surfaceColor: '#FFFFFF',
      textColor: '#312E81',
      mutedTextColor: '#7C3AED',
      borderColor: '#DDD6FE',
      radius: '2rem',
      fontHeading: 'Outfit, Inter, system-ui, sans-serif',
      fontBody: 'Outfit, Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'gradient',
      value: 'radial-gradient(circle at 20% 20%, #FDE68A, transparent 28%), radial-gradient(circle at 80% 30%, #FBCFE8, transparent 28%), radial-gradient(circle at 50% 90%, #C4B5FD, transparent 30%), #FFF7ED',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(255,255,255,0)',
    },
  },
  retro: {
    id: 'retro',
    name: 'Retro',
    description: 'Warm vintage booth look.',
    tokens: {
      primaryColor: '#B45309',
      secondaryColor: '#FED7AA',
      accentColor: '#EA580C',
      backgroundColor: '#FFF7ED',
      surfaceColor: '#FFFBEB',
      textColor: '#431407',
      mutedTextColor: '#9A3412',
      borderColor: '#FDBA74',
      radius: '1.4rem',
      fontHeading: 'Playfair Display, Georgia, serif',
      fontBody: 'Outfit, Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'gradient',
      value: 'linear-gradient(135deg, #FFF7ED 0%, #FED7AA 100%)',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(120,53,15,0.08)',
    },
  },
  minimal: {
    id: 'minimal',
    name: 'Minimal',
    description: 'Plain monochrome interface.',
    tokens: {
      primaryColor: '#18181B',
      secondaryColor: '#F4F4F5',
      accentColor: '#71717A',
      backgroundColor: '#FAFAFA',
      surfaceColor: '#FFFFFF',
      textColor: '#18181B',
      mutedTextColor: '#71717A',
      borderColor: '#E4E4E7',
      radius: '1rem',
      fontHeading: 'Inter, system-ui, sans-serif',
      fontBody: 'Inter, system-ui, sans-serif',
    },
    defaultBackground: {
      type: 'solid',
      value: '#FAFAFA',
      fit: 'cover',
      opacity: 1,
      overlayColor: 'rgba(255,255,255,0)',
    },
  },
};

export function getThemePreset(themeId: CorraThemeId): CorraThemePreset {
  return CORRA_THEME_PRESETS[themeId] || CORRA_THEME_PRESETS.y2k;
}
TS

echo ""
echo "Writing default brand config..."

write_file "apps/booth-ui/src/branding/default-brand-config.ts" <<'TS'
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
TS

echo ""
echo "Writing local brand config storage..."

write_file "apps/booth-ui/src/branding/local-brand-config.ts" <<'TS'
import { DEFAULT_CORRA_BRAND_CONFIG } from './default-brand-config';
import type { CorraBrandConfig } from './types';

const STORAGE_KEY = 'corra.brandConfig.v1';

export function loadLocalBrandConfig(): CorraBrandConfig {
  if (typeof window === 'undefined') {
    return DEFAULT_CORRA_BRAND_CONFIG;
  }

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);

    if (!raw) {
      return DEFAULT_CORRA_BRAND_CONFIG;
    }

    return {
      ...DEFAULT_CORRA_BRAND_CONFIG,
      ...JSON.parse(raw),
      appearance: {
        ...DEFAULT_CORRA_BRAND_CONFIG.appearance,
        ...(JSON.parse(raw).appearance || {}),
      },
    };
  } catch {
    return DEFAULT_CORRA_BRAND_CONFIG;
  }
}

export function saveLocalBrandConfig(config: CorraBrandConfig): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
}

export function clearLocalBrandConfig(): void {
  if (typeof window === 'undefined') {
    return;
  }

  window.localStorage.removeItem(STORAGE_KEY);
}
TS

echo ""
echo "Writing BrandThemeProvider..."

write_file "apps/booth-ui/src/branding/BrandThemeProvider.tsx" <<'TSX'
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
TSX

echo ""
echo "Writing themed background and brand name components..."

write_file "apps/booth-ui/src/branding/ThemedBackground.tsx" <<'TSX'
import React from 'react';
import { useBrandTheme } from './BrandThemeProvider';

export function ThemedBackground() {
  const { brandConfig, activeTheme } = useBrandTheme();
  const appearance = brandConfig.appearance;
  const fallback = activeTheme.defaultBackground;

  const type = appearance.backgroundType || fallback.type;
  const value = appearance.backgroundValue || fallback.value;
  const fit = appearance.backgroundFit || fallback.fit;
  const opacity = appearance.backgroundOpacity ?? fallback.opacity;
  const overlayColor = appearance.overlayColor || fallback.overlayColor;

  const objectFit =
    fit === 'contain' ? 'contain' : fit === 'fill' ? 'fill' : 'cover';

  return (
    <div className="corra-themed-background" aria-hidden="true">
      {type === 'video' && value ? (
        <video
          className="corra-themed-background-media"
          src={value}
          autoPlay
          muted
          loop
          playsInline
          style={{
            objectFit,
            opacity,
          }}
        />
      ) : null}

      {type === 'image' && value ? (
        <div
          className="corra-themed-background-media"
          style={{
            backgroundImage: `url("${value}")`,
            backgroundSize: objectFit,
            backgroundPosition: 'center',
            backgroundRepeat: 'no-repeat',
            opacity,
          }}
        />
      ) : null}

      {(type === 'gradient' || type === 'solid') && (
        <div
          className="corra-themed-background-media"
          style={{
            background: value,
            opacity,
          }}
        />
      )}

      <div
        className="corra-themed-background-overlay"
        style={{
          background: overlayColor,
        }}
      />
    </div>
  );
}
TSX

write_file "apps/booth-ui/src/branding/BrandName.tsx" <<'TSX'
import React from 'react';
import { useBrandTheme } from './BrandThemeProvider';

type BrandNameProps = {
  fallback?: string;
  className?: string;
};

export function BrandName({
  fallback = 'Corra Studio',
  className,
}: BrandNameProps) {
  const { brandConfig } = useBrandTheme();

  return (
    <span className={className}>
      {brandConfig.businessName || fallback}
    </span>
  );
}
TSX

write_file "apps/booth-ui/src/branding/index.ts" <<'TS'
export * from './types';
export * from './theme-presets';
export * from './default-brand-config';
export * from './local-brand-config';
export * from './BrandThemeProvider';
export * from './ThemedBackground';
export * from './BrandName';
TS

echo ""
echo "Writing admin appearance panel foundation..."

write_file "apps/booth-ui/src/components/admin/BrandAppearancePanel.tsx" <<'TSX'
import React from 'react';
import { CORRA_THEME_PRESETS, useBrandTheme, type CorraThemeId } from '../../branding';

export default function BrandAppearancePanel() {
  const { brandConfig, updateBrandConfig, resetBrandConfig } = useBrandTheme();

  return (
    <div className="rounded-3xl border border-[var(--corra-border)] bg-[var(--corra-surface)] p-6 text-[var(--corra-text)]">
      <div className="mb-5">
        <h2 className="font-black text-2xl">Brand & Appearance</h2>
        <p className="text-sm text-[var(--corra-muted)]">
          White-label settings for customer brand, theme, and UI background.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">Business Name</span>
          <input
            value={brandConfig.businessName}
            onChange={(event) => updateBrandConfig({ businessName: event.target.value })}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">Tagline</span>
          <input
            value={brandConfig.tagline}
            onChange={(event) => updateBrandConfig({ tagline: event.target.value })}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">Theme</span>
          <select
            value={brandConfig.themeId}
            onChange={(event) => updateBrandConfig({ themeId: event.target.value as CorraThemeId })}
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            {Object.values(CORRA_THEME_PRESETS).map((theme) => (
              <option key={theme.id} value={theme.id}>
                {theme.name}
              </option>
            ))}
          </select>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">Background Type</span>
          <select
            value={brandConfig.appearance.backgroundType}
            onChange={(event) =>
              updateBrandConfig({
                appearance: {
                  ...brandConfig.appearance,
                  backgroundType: event.target.value as typeof brandConfig.appearance.backgroundType,
                },
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            <option value="gradient">Gradient</option>
            <option value="solid">Solid Color</option>
            <option value="image">Image PNG/JPG/WebP URL</option>
            <option value="video">Video MP4 URL</option>
          </select>
        </label>

        <label className="space-y-2 md:col-span-2">
          <span className="text-xs font-black uppercase tracking-wider">Background Value</span>
          <input
            value={brandConfig.appearance.backgroundValue}
            onChange={(event) =>
              updateBrandConfig({
                appearance: {
                  ...brandConfig.appearance,
                  backgroundValue: event.target.value,
                },
              })
            }
            placeholder="URL / local path / CSS gradient / color"
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>
      </div>

      <button
        type="button"
        onClick={resetBrandConfig}
        className="mt-5 rounded-2xl bg-[var(--corra-primary)] px-5 py-3 text-sm font-black text-white"
      >
        Reset to Default
      </button>
    </div>
  );
}
TSX

echo ""
echo "Patching main.tsx..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/main.tsx")
text = path.read_text()

if "BrandThemeProvider" not in text:
    text = text.replace(
        "import './index.css';",
        "import './index.css';\nimport { BrandThemeProvider, ThemedBackground } from './branding';"
    )

if "<BrandThemeProvider>" not in text:
    text = text.replace(
        "<App />",
        "<BrandThemeProvider>\n      <ThemedBackground />\n      <App />\n    </BrandThemeProvider>"
    )

path.write_text(text)
print("PATCH file: apps/booth-ui/src/main.tsx")
PY

echo ""
echo "Appending theme CSS..."

cat >> apps/booth-ui/src/index.css <<'CSS'

/* Corra white-label theme variables */
:root {
  --corra-primary: #EC4899;
  --corra-secondary: #F9A8D4;
  --corra-accent: #FACC15;
  --corra-bg: #FFF1F7;
  --corra-surface: #FFFFFF;
  --corra-text: #1C1917;
  --corra-muted: #78716C;
  --corra-border: #FBCFE8;
  --corra-radius: 2rem;
  --corra-font-heading: "Playfair Display", Georgia, serif;
  --corra-font-body: Outfit, Inter, system-ui, sans-serif;
}

body {
  background: var(--corra-bg);
}

.corra-themed-background {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
  background: var(--corra-bg);
}

.corra-themed-background-media,
.corra-themed-background-overlay {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.corra-themed-background-media {
  display: block;
}

.corra-themed-background-overlay {
  pointer-events: none;
}
CSS

echo ""
echo "Writing docs..."

write_file "docs/phase-7c1-brand-theme-background-foundation.md" <<'MD'
# Phase 7C1 - Brand Theme Background Foundation

This phase introduces the white-label foundation for Corra Booth.

## Added

- Brand config
- Theme presets
- Background config
- BrandThemeProvider
- ThemedBackground
- BrandName component
- Admin BrandAppearancePanel foundation

## Supported Themes

- y2k
- wedding
- clean
- luxury
- corporate
- kids
- retro
- minimal

## Supported UI Backgrounds

- gradient
- solid
- image URL
- video MP4 URL

## Important

This phase creates the foundation. Full admin integration and file upload for PNG/MP4 should be added in the next phase.
MD

echo ""
echo "Verifying..."

[ -f "apps/booth-ui/src/branding/index.ts" ] || fail "Missing branding index."
[ -f "apps/booth-ui/src/branding/BrandThemeProvider.tsx" ] || fail "Missing BrandThemeProvider."
[ -f "apps/booth-ui/src/components/admin/BrandAppearancePanel.tsx" ] || fail "Missing BrandAppearancePanel."
grep -q "BrandThemeProvider" apps/booth-ui/src/main.tsx || fail "main.tsx not wrapped with BrandThemeProvider."
grep -q "vendor/electron/" .gitignore || fail ".gitignore missing vendor/electron entry."

echo ""
echo "========================================"
echo " Phase 7C1 completed."
echo "========================================"
echo ""
echo "Next:"
echo "  pnpm --filter @corra/booth-ui typecheck"
echo "  pnpm --filter @corra/booth-ui dev -- --host 0.0.0.0 --port 5173"
echo "  git add ."
echo "  git commit -m \"feat: add brand theme background foundation\""
echo "  git push origin main"
echo ""
