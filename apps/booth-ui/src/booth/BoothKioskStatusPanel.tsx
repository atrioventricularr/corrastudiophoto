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
