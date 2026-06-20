import React from 'react';
import App from './App';
import { BoothModePage } from './booth';

function isBoothModeUrl() {
  if (typeof window === 'undefined') return false;

  const url = new URL(window.location.href);
  const mode = url.searchParams.get('mode');
  const booth = url.searchParams.get('booth');
  const hash = window.location.hash.toLowerCase();
  const pathname = window.location.pathname.toLowerCase();

  return (
    mode === 'booth' ||
    booth === '1' ||
    hash === '#/booth' ||
    hash === '#booth' ||
    pathname.endsWith('/booth')
  );
}

export function AppModeRouter() {
  if (isBoothModeUrl()) {
    return <BoothModePage />;
  }

  return <App />;
}
