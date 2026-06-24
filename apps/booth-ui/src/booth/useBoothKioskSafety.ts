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
