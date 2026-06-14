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
