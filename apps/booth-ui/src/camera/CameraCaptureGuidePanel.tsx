import React, {
  useEffect,
  useMemo,
  useState,
} from 'react';
import { useLayouts } from '../layouts';
import {
  getCaptureGuideStep,
  getCaptureOrderedSlots,
} from './capture-guide';

export function CameraCaptureGuidePanel() {
  const { activeLayout } = useLayouts();
  const [activeIndex, setActiveIndex] = useState(0);

  const orderedSlots = useMemo(
    () => getCaptureOrderedSlots(activeLayout),
    [activeLayout],
  );

  const activeStep = getCaptureGuideStep({
    layout: activeLayout,
    index: activeIndex,
  });

  useEffect(() => {
    if (activeIndex > orderedSlots.length - 1) {
      setActiveIndex(Math.max(0, orderedSlots.length - 1));
    }
  }, [activeIndex, orderedSlots.length]);

  if (!activeStep) {
    return (
      <section className="rounded-3xl border border-amber-200 bg-amber-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-amber-500">
          Capture Guide
        </p>
        <p className="mt-2 text-sm font-bold text-amber-800">
          Belum ada slot guide aktif di layout ini.
        </p>
      </section>
    );
  }

  const isFirst = activeStep.index === 0;
  const isLast = activeStep.index === activeStep.total - 1;

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Capture Guide
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {activeStep.label}
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Slot {activeStep.index + 1} dari {activeStep.total} ·{' '}
            {activeStep.slot.name}
          </p>
        </div>

        <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black text-white">
          #{activeStep.slot.captureOrder}
        </span>
      </div>

      <div className="mt-4 h-3 overflow-hidden rounded-full bg-slate-100">
        <div
          className="h-full rounded-full bg-slate-950"
          style={{
            width: `${((activeStep.index + 1) / activeStep.total) * 100}%`,
          }}
        />
      </div>

      <div className="mt-4 grid gap-2 sm:grid-cols-3">
        <button
          type="button"
          onClick={() => setActiveIndex((current) => Math.max(0, current - 1))}
          disabled={isFirst}
          className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-xs font-black text-slate-700 disabled:opacity-40"
        >
          Previous Pose
        </button>

        <button
          type="button"
          onClick={() => setActiveIndex(0)}
          className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-xs font-black text-slate-700"
        >
          Reset
        </button>

        <button
          type="button"
          onClick={() =>
            setActiveIndex((current) =>
              Math.min(orderedSlots.length - 1, current + 1),
            )
          }
          disabled={isLast}
          className="rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white disabled:opacity-40"
        >
          Next Pose
        </button>
      </div>

      <div className="mt-4 grid gap-2">
        {orderedSlots.map((slot, index) => (
          <button
            key={slot.id}
            type="button"
            onClick={() => setActiveIndex(index)}
            className={`rounded-2xl px-4 py-3 text-left text-xs font-black ${
              index === activeStep.index
                ? 'bg-blue-600 text-white'
                : 'bg-slate-50 text-slate-600'
            }`}
          >
            {index + 1}. {slot.guideLabel || slot.name}
          </button>
        ))}
      </div>
    </section>
  );
}
