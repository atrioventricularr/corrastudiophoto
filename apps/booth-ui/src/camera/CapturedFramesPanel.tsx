import React from 'react';
import { useLayouts } from '../layouts';
import { useCapturedFrames } from './CapturedFramesProvider';

export function CapturedFramesPanel() {
  const { activeLayout } = useLayouts();
  const {
    capturedFramesBySlotId,
    removeCapturedFrame,
    clearCapturedFrames,
  } = useCapturedFrames();

  const capturedCount = Object.keys(capturedFramesBySlotId).length;

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Captured Frames
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {capturedCount} / {activeLayout.slots.length} Slots Captured
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Hasil capture sementara per slot layout aktif.
          </p>
        </div>

        <button
          type="button"
          onClick={clearCapturedFrames}
          disabled={capturedCount === 0}
          className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-black text-red-700 disabled:opacity-40"
        >
          Clear All
        </button>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {activeLayout.slots.map((slot) => {
          const frame = capturedFramesBySlotId[slot.id];

          return (
            <div
              key={slot.id}
              className="rounded-2xl border border-slate-100 bg-slate-50 p-3"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="text-sm font-black text-slate-800">
                    #{slot.captureOrder} · {slot.name}
                  </p>
                  <p className="mt-1 text-xs font-bold text-slate-500">
                    {frame ? 'Captured' : 'Waiting'}
                  </p>
                </div>

                {frame && (
                  <button
                    type="button"
                    onClick={() => removeCapturedFrame(slot.id)}
                    className="rounded-xl border border-red-200 bg-white px-3 py-2 text-[10px] font-black text-red-700"
                  >
                    Remove
                  </button>
                )}
              </div>

              {frame ? (
                <img
                  src={frame.dataUrl}
                  alt={slot.name}
                  className="mt-3 h-28 w-full rounded-xl border border-slate-200 bg-white object-cover"
                />
              ) : (
                <div className="mt-3 flex h-28 items-center justify-center rounded-xl border border-dashed border-slate-300 bg-white text-xs font-bold text-slate-400">
                  No photo yet
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
