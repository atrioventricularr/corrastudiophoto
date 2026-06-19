import React from 'react';
import {
  createLayoutSlot,
  useLayouts,
  type PhotoSlotCropMode,
  type PhotoSlotShape,
} from '../../layouts';

function toNumber(value: string, fallback = 0): number {
  const parsed = Number(value);

  if (Number.isNaN(parsed)) {
    return fallback;
  }

  return parsed;
}

function clampPercent(value: number): number {
  return Math.max(0, Math.min(100, value));
}

export function LayoutSlotEditorPanel() {
  const {
    activeLayout,
    addSlot,
    updateSlot,
    removeSlot,
  } = useLayouts();

  const handleAddSlot = () => {
    const nextOrder =
      Math.max(0, ...activeLayout.slots.map((slot) => slot.captureOrder)) + 1;

    addSlot(
      activeLayout.id,
      createLayoutSlot({
        id: `slot-${Date.now()}`,
        name: `Photo ${nextOrder}`,
        captureOrder: nextOrder,
        xPercent: 10,
        yPercent: 10,
        widthPercent: 35,
        heightPercent: 35,
        shape: 'rectangle',
        cropMode: 'cover',
        guideLabel: `Pose ${nextOrder}`,
        showGuide: true,
      }),
    );
  };

  return (
    <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Slot Editor
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            Photo Slot Position
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Atur posisi slot foto dalam persen dari canvas. Preview layout akan
            ikut berubah otomatis.
          </p>
        </div>

        <button
          type="button"
          onClick={handleAddSlot}
          className="rounded-2xl bg-slate-950 px-5 py-3 text-sm font-black text-white"
        >
          Add Slot
        </button>
      </div>

      <div className="mt-5 space-y-4">
        {activeLayout.slots.map((slot) => (
          <div
            key={slot.id}
            className="rounded-3xl border border-slate-100 bg-slate-50 p-4"
          >
            <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <p className="font-mono text-xs font-black text-slate-400">
                  {slot.id}
                </p>
                <h5 className="mt-1 text-lg font-black text-slate-950">
                  #{slot.captureOrder} · {slot.name}
                </h5>
              </div>

              <button
                type="button"
                onClick={() => removeSlot(activeLayout.id, slot.id)}
                className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-xs font-black text-red-700"
              >
                Remove
              </button>
            </div>

            <div className="mt-4 grid gap-4 lg:grid-cols-4">
              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Name
                </span>
                <input
                  value={slot.name}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      name: event.target.value,
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Guide Label
                </span>
                <input
                  value={slot.guideLabel}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      guideLabel: event.target.value,
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Order
                </span>
                <input
                  type="number"
                  value={slot.captureOrder}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      captureOrder: toNumber(
                        event.target.value,
                        slot.captureOrder,
                      ),
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>

              <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
                <input
                  type="checkbox"
                  checked={slot.showGuide}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      showGuide: event.target.checked,
                    })
                  }
                />
                <span className="text-sm font-black text-slate-700">
                  Show guide
                </span>
              </label>
            </div>

            <div className="mt-4 grid gap-4 lg:grid-cols-4">
              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  X %
                </span>
                <input
                  type="number"
                  step="0.5"
                  value={slot.xPercent}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      xPercent: clampPercent(
                        toNumber(event.target.value, slot.xPercent),
                      ),
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Y %
                </span>
                <input
                  type="number"
                  step="0.5"
                  value={slot.yPercent}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      yPercent: clampPercent(
                        toNumber(event.target.value, slot.yPercent),
                      ),
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Width %
                </span>
                <input
                  type="number"
                  step="0.5"
                  value={slot.widthPercent}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      widthPercent: clampPercent(
                        toNumber(event.target.value, slot.widthPercent),
                      ),
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Height %
                </span>
                <input
                  type="number"
                  step="0.5"
                  value={slot.heightPercent}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      heightPercent: clampPercent(
                        toNumber(event.target.value, slot.heightPercent),
                      ),
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>
            </div>

            <div className="mt-4 grid gap-4 lg:grid-cols-4">
              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Shape
                </span>
                <select
                  value={slot.shape}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      shape: event.target.value as PhotoSlotShape,
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                >
                  <option value="rectangle">Rectangle</option>
                  <option value="square">Square</option>
                  <option value="circle">Circle</option>
                </select>
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Crop Mode
                </span>
                <select
                  value={slot.cropMode}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      cropMode: event.target.value as PhotoSlotCropMode,
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                >
                  <option value="cover">Cover</option>
                  <option value="contain">Contain</option>
                  <option value="fill">Fill</option>
                </select>
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Radius %
                </span>
                <input
                  type="number"
                  step="0.5"
                  value={slot.borderRadiusPercent}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      borderRadiusPercent: clampPercent(
                        toNumber(
                          event.target.value,
                          slot.borderRadiusPercent,
                        ),
                      ),
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>

              <label className="block">
                <span className="text-xs font-black uppercase tracking-wider text-slate-400">
                  Rotation °
                </span>
                <input
                  type="number"
                  step="1"
                  value={slot.rotationDeg}
                  onChange={(event) =>
                    updateSlot(activeLayout.id, slot.id, {
                      rotationDeg: toNumber(
                        event.target.value,
                        slot.rotationDeg,
                      ),
                    })
                  }
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
                />
              </label>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
