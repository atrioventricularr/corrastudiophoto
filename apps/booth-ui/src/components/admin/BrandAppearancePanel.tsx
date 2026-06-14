import React, { useMemo, useState } from 'react';
import {
  CORRA_THEME_PRESETS,
  useBrandTheme,
  type CorraBackgroundFit,
  type CorraBackgroundType,
  type CorraThemeId,
} from '../../branding';
import {
  isDesktopBackgroundPickerAvailable,
  pickDesktopBackgroundAsset,
} from '../../lib/desktop-assets';

export default function BrandAppearancePanel() {
  const { brandConfig, updateBrandConfig, resetBrandConfig } = useBrandTheme();
  const [message, setMessage] = useState<string>('');
  const canPickLocalBackground = useMemo(
    () => isDesktopBackgroundPickerAvailable(),
    [],
  );

  const updateAppearance = (
    patch: Partial<typeof brandConfig.appearance>,
  ) => {
    updateBrandConfig({
      appearance: {
        ...brandConfig.appearance,
        ...patch,
      },
    });
  };

  const handlePickLocalBackground = async () => {
    setMessage('');

    const result = await pickDesktopBackgroundAsset();

    if (result.cancelled) {
      if (result.error) {
        setMessage(result.error);
      }

      return;
    }

    if (!result.url || !result.backgroundType) {
      setMessage('Background file selected, but no usable asset URL was returned.');
      return;
    }

    updateAppearance({
      backgroundType: result.backgroundType,
      backgroundValue: result.url,
      backgroundFit: 'cover',
      backgroundOpacity: 1,
    });

    setMessage(`Background selected: ${result.filename || result.url}`);
  };

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
          <span className="text-xs font-black uppercase tracking-wider">
            Business Name
          </span>
          <input
            value={brandConfig.businessName}
            onChange={(event) =>
              updateBrandConfig({ businessName: event.target.value })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Tagline
          </span>
          <input
            value={brandConfig.tagline}
            onChange={(event) =>
              updateBrandConfig({ tagline: event.target.value })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Theme
          </span>
          <select
            value={brandConfig.themeId}
            onChange={(event) =>
              updateBrandConfig({
                themeId: event.target.value as CorraThemeId,
              })
            }
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
          <span className="text-xs font-black uppercase tracking-wider">
            Background Type
          </span>
          <select
            value={brandConfig.appearance.backgroundType}
            onChange={(event) =>
              updateAppearance({
                backgroundType: event.target.value as CorraBackgroundType,
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            <option value="gradient">Gradient</option>
            <option value="solid">Solid Color</option>
            <option value="image">Image PNG/JPG/WebP</option>
            <option value="video">Video MP4 Loop</option>
          </select>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Background Fit
          </span>
          <select
            value={brandConfig.appearance.backgroundFit}
            onChange={(event) =>
              updateAppearance({
                backgroundFit: event.target.value as CorraBackgroundFit,
              })
            }
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          >
            <option value="cover">Cover</option>
            <option value="contain">Contain</option>
            <option value="fill">Fill</option>
          </select>
        </label>

        <label className="space-y-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Background Opacity
          </span>
          <input
            value={brandConfig.appearance.backgroundOpacity}
            onChange={(event) =>
              updateAppearance({
                backgroundOpacity: Number(event.target.value),
              })
            }
            min={0}
            max={1}
            step={0.05}
            type="number"
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>

        <label className="space-y-2 md:col-span-2">
          <span className="text-xs font-black uppercase tracking-wider">
            Background Value
          </span>
          <input
            value={brandConfig.appearance.backgroundValue}
            onChange={(event) =>
              updateAppearance({
                backgroundValue: event.target.value,
              })
            }
            placeholder="corra-asset://... / URL / CSS gradient / color"
            className="w-full rounded-2xl border border-[var(--corra-border)] bg-white px-4 py-3 text-sm outline-none"
          />
        </label>
      </div>

      <div className="mt-5 flex flex-col sm:flex-row gap-3">
        <button
          type="button"
          onClick={handlePickLocalBackground}
          disabled={!canPickLocalBackground}
          className="rounded-2xl bg-[var(--corra-primary)] px-5 py-3 text-sm font-black text-white disabled:opacity-50"
        >
          Pick Local PNG/JPG/WebP/MP4
        </button>

        <button
          type="button"
          onClick={resetBrandConfig}
          className="rounded-2xl border border-[var(--corra-border)] bg-white px-5 py-3 text-sm font-black text-[var(--corra-text)]"
        >
          Reset to Default
        </button>
      </div>

      {!canPickLocalBackground && (
        <p className="mt-3 text-xs text-[var(--corra-muted)]">
          Local file picker is only available inside Electron desktop. Browser
          preview can still use URL, CSS color, or CSS gradient manually.
        </p>
      )}

      {message && (
        <div className="mt-4 rounded-2xl border border-[var(--corra-border)] bg-white/70 p-3 text-xs font-bold text-[var(--corra-muted)]">
          {message}
        </div>
      )}
    </div>
  );
}
