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
