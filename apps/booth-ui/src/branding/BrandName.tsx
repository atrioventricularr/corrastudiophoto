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
