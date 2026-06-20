import React from 'react';
import { useBoothLifecycleLogger } from './BoothLifecycleLoggerProvider';

function downloadJson(filename: string, data: unknown) {
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json',
  });

  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');

  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();

  URL.revokeObjectURL(url);
}

export function BoothLifecycleDebugPanel() {
  const {
    events,
    latestEvent,
    clearBoothEvents,
  } = useBoothLifecycleLogger();

  const latestEvents = events.slice(-8).reverse();

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Lifecycle Events
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            {events.length} local event(s) recorded.
          </p>

          {latestEvent && (
            <p className="mt-1 text-xs font-bold text-emerald-200">
              Latest: {latestEvent.type}
            </p>
          )}
        </div>

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() =>
              downloadJson(
                `corra-booth-lifecycle-${new Date()
                  .toISOString()
                  .replace(/[:.]/g, '-')}.json`,
                events,
              )
            }
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
          >
            Export JSON
          </button>

          <button
            type="button"
            onClick={clearBoothEvents}
            className="rounded-2xl border border-red-300/30 bg-red-500/20 px-3 py-2 text-xs font-black text-red-100"
          >
            Clear Log
          </button>
        </div>
      </div>

      <div className="mt-4 grid gap-2">
        {latestEvents.length === 0 && (
          <div className="rounded-2xl bg-white/10 p-3 text-xs font-bold text-white/50">
            No lifecycle events yet.
          </div>
        )}

        {latestEvents.map((event) => (
          <div
            key={event.id}
            className="rounded-2xl bg-white/10 p-3"
          >
            <div className="flex flex-col gap-1 sm:flex-row sm:items-start sm:justify-between">
              <p className="text-xs font-black uppercase tracking-[0.14em] text-white">
                {event.type}
              </p>

              <p className="font-mono text-[10px] font-bold text-white/40">
                {new Date(event.at).toLocaleTimeString()}
              </p>
            </div>

            <p className="mt-1 text-xs font-semibold text-white/60">
              {event.summary}
            </p>

            <p className="mt-1 break-all font-mono text-[10px] font-bold text-white/35">
              {event.sessionId || 'no-session'} · {event.step || 'no-step'} ·{' '}
              {event.paymentStatus || 'no-payment'}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}
