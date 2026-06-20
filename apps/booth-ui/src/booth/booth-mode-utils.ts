export function getBoothUrlMode() {
  if (typeof window === 'undefined') {
    return {
      isBoothMode: false,
      isDevMode: false,
      isKioskMode: false,
    };
  }

  const url = new URL(window.location.href);
  const hash = window.location.hash.toLowerCase();
  const pathname = window.location.pathname.toLowerCase();

  const isBoothMode =
    url.searchParams.get('mode') === 'booth' ||
    url.searchParams.get('booth') === '1' ||
    hash === '#/booth' ||
    hash === '#booth' ||
    pathname.endsWith('/booth');

  const isDevMode =
    url.searchParams.get('dev') === '1' ||
    url.searchParams.get('boothDev') === '1' ||
    hash.includes('booth-dev');

  const isKioskMode =
    url.searchParams.get('kiosk') === '1' ||
    url.searchParams.get('fullscreen') === '1';

  return {
    isBoothMode,
    isDevMode,
    isKioskMode,
  };
}

export function goToAdminMode() {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.delete('mode');
  url.searchParams.delete('booth');
  url.searchParams.delete('dev');
  url.searchParams.delete('boothDev');
  url.searchParams.delete('kiosk');
  url.searchParams.delete('fullscreen');
  url.hash = '';

  window.location.href = url.toString();
}

export function goToBoothMode(input: {
  dev?: boolean;
  kiosk?: boolean;
} = {}) {
  if (typeof window === 'undefined') return;

  const url = new URL(window.location.href);
  url.searchParams.set('mode', 'booth');

  if (input.dev) {
    url.searchParams.set('dev', '1');
  } else {
    url.searchParams.delete('dev');
    url.searchParams.delete('boothDev');
  }

  if (input.kiosk) {
    url.searchParams.set('kiosk', '1');
  } else {
    url.searchParams.delete('kiosk');
    url.searchParams.delete('fullscreen');
  }

  url.hash = '';
  window.location.href = url.toString();
}

export function buildBoothModeHref(input: {
  dev?: boolean;
  kiosk?: boolean;
} = {}) {
  if (typeof window === 'undefined') {
    return '?mode=booth';
  }

  const url = new URL(window.location.href);
  url.searchParams.set('mode', 'booth');

  if (input.dev) {
    url.searchParams.set('dev', '1');
  } else {
    url.searchParams.delete('dev');
    url.searchParams.delete('boothDev');
  }

  if (input.kiosk) {
    url.searchParams.set('kiosk', '1');
  } else {
    url.searchParams.delete('kiosk');
    url.searchParams.delete('fullscreen');
  }

  url.hash = '';

  return `${url.pathname}${url.search}`;
}
