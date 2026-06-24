#!/usr/bin/env bash
set -euo pipefail

mkdir -p apps/booth-ui/src/booth

cat > apps/booth-ui/src/booth/useBoothKioskSafety.ts <<'TS'
import { useCallback, useEffect, useMemo, useState } from 'react';

type UseBoothKioskSafetyInput = {
  isKioskMode: boolean;
  isDevMode: boolean;
};

function isFullscreenActive() {
  return typeof document !== 'undefined' && Boolean(document.fullscreenElement);
}

function shouldBlockShortcut(event: KeyboardEvent) {
  const key = event.key.toLowerCase();
  const target = event.target as HTMLElement | null;
  const tag = target?.tagName?.toLowerCase();
  const isTyping =
    tag === 'input' || tag === 'textarea' || Boolean(target?.isContentEditable);

  if (key === 'f5') return true;
  if ((event.ctrlKey || event.metaKey) && ['r', 'w', 'l'].includes(key)) {
    return true;
  }
  if (!isTyping && key === 'backspace') return true;

  return false;
}

export function useBoothKioskSafety({
  isKioskMode,
  isDevMode,
}: UseBoothKioskSafetyInput) {
  const [isFullscreen, setIsFullscreen] = useState(() => isFullscreenActive());
  const [blockedContextMenuCount, setBlockedContextMenuCount] = useState(0);
  const [blockedShortcutCount, setBlockedShortcutCount] = useState(0);

  const requestFullscreen = useCallback(async () => {
    if (!document.documentElement.requestFullscreen) return false;

    try {
      await document.documentElement.requestFullscreen();
      setIsFullscreen(true);
      return true;
    } catch {
      return false;
    }
  }, []);

  const exitFullscreen = useCallback(async () => {
    if (!document.exitFullscreen || !document.fullscreenElement) return false;

    try {
      await document.exitFullscreen();
      setIsFullscreen(false);
      return true;
    } catch {
      return false;
    }
  }, []);

  useEffect(() => {
    const onFullscreenChange = () => setIsFullscreen(isFullscreenActive());
    document.addEventListener('fullscreenchange', onFullscreenChange);

    return () => {
      document.removeEventListener('fullscreenchange', onFullscreenChange);
    };
  }, []);

  useEffect(() => {
    if (!isKioskMode || isDevMode) return;

    const onContextMenu = (event: MouseEvent) => {
      event.preventDefault();
      setBlockedContextMenuCount((current) => current + 1);
    };

    const onKeyDown = (event: KeyboardEvent) => {
      if (!shouldBlockShortcut(event)) return;
      event.preventDefault();
      event.stopPropagation();
      setBlockedShortcutCount((current) => current + 1);
    };

    window.addEventListener('contextmenu', onContextMenu);
    window.addEventListener('keydown', onKeyDown, true);

    return () => {
      window.removeEventListener('contextmenu', onContextMenu);
      window.removeEventListener('keydown', onKeyDown, true);
    };
  }, [isDevMode, isKioskMode]);

  const state = useMemo(() => {
    return {
      isFullscreen,
      isKioskMode,
      isDevMode,
      blockedContextMenuCount,
      blockedShortcutCount,
    };
  }, [
    blockedContextMenuCount,
    blockedShortcutCount,
    isDevMode,
    isFullscreen,
    isKioskMode,
  ]);

  return {
    state,
    requestFullscreen,
    exitFullscreen,
  };
}
TS

cat > apps/booth-ui/src/booth/BoothKioskStatusPanel.tsx <<'TSX'
import React from 'react';

type BoothKioskStatusPanelProps = {
  state: {
    isFullscreen: boolean;
    isKioskMode: boolean;
    isDevMode: boolean;
    blockedContextMenuCount: number;
    blockedShortcutCount: number;
  };
  onRequestFullscreen: () => void;
  onExitFullscreen: () => void;
};

export function BoothKioskStatusPanel({
  state,
  onRequestFullscreen,
  onExitFullscreen,
}: BoothKioskStatusPanelProps) {
  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
        Kiosk Safety
      </p>

      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Fullscreen</p>
          <p className="mt-1 text-sm font-black text-white">
            {state.isFullscreen ? 'Active' : 'Inactive'}
          </p>
        </div>

        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Kiosk</p>
          <p className="mt-1 text-sm font-black text-white">
            {state.isKioskMode ? 'Active' : 'Inactive'}
          </p>
        </div>

        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Context</p>
          <p className="mt-1 text-sm font-black text-white">
            {state.blockedContextMenuCount}
          </p>
        </div>

        <div className="rounded-2xl bg-white/10 p-3">
          <p className="text-xs font-black uppercase text-white/40">Shortcuts</p>
          <p className="mt-1 text-sm font-black text-white">
            {state.blockedShortcutCount}
          </p>
        </div>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <button
          type="button"
          onClick={onRequestFullscreen}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
        >
          Request Fullscreen
        </button>

        <button
          type="button"
          onClick={onExitFullscreen}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-3 text-xs font-black text-white"
        >
          Exit Fullscreen
        </button>
      </div>
    </section>
  );
}
TSX

grep -q "useBoothKioskSafety" apps/booth-ui/src/booth/index.ts || cat >> apps/booth-ui/src/booth/index.ts <<'TS'
export * from './useBoothKioskSafety';
export * from './BoothKioskStatusPanel';
TS

echo "9B19 minimal kiosk files done."
