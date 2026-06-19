#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10B1B - Printer Profile Panel"
echo "========================================"

mkdir -p apps/booth-ui/src/components/admin

cat > apps/booth-ui/src/components/admin/PrinterProfilePanel.tsx <<'TSX'
import React from 'react';
import {
  usePrinterProfile,
  type PrintOrientation,
  type PrinterType,
} from '../../print';

function toNumber(value: string, fallback = 0): number {
  const parsed = Number(value);

  if (Number.isNaN(parsed)) {
    return fallback;
  }

  return parsed;
}

export function PrinterProfilePanel() {
  const { printerProfile, updatePrinterProfile, resetPrinterProfile } =
    usePrinterProfile();

  const canvasWidthPx =
    printerProfile.orientation === 'landscape'
      ? Math.round(printerProfile.paperHeightInch * printerProfile.dpi)
      : Math.round(printerProfile.paperWidthInch * printerProfile.dpi);

  const canvasHeightPx =
    printerProfile.orientation === 'landscape'
      ? Math.round(printerProfile.paperWidthInch * printerProfile.dpi)
      : Math.round(printerProfile.paperHeightInch * printerProfile.dpi);

  const applyDnp4rPreset = () => {
    updatePrinterProfile({
      id: 'dnp-4r-booth',
      name: 'DNP 4R Booth',
      printerType: 'DNP',
      printerModel: 'DNP DS-RX1HS',
      paperName: '4R / 4x6 inch',
      paperWidthInch: 4,
      paperHeightInch: 6,
      orientation: 'portrait',
      dpi: 300,
      borderless: true,
      rotateBeforePrint: false,
      marginPx: {
        top: 0,
        right: 0,
        bottom: 0,
        left: 0,
      },
      offsetPx: {
        x: 0,
        y: 0,
      },
      scalePercent: 100,
      notes:
        'DNP 4R default. Adjust offset X/Y and scale if print shifts.',
    });
  };

  const applyInkjetA4Preset = () => {
    updatePrinterProfile({
      id: 'inkjet-a4',
      name: 'Home Inkjet A4',
      printerType: 'INKJET',
      printerModel: 'Generic Inkjet Printer',
      paperName: 'A4',
      paperWidthInch: 8.27,
      paperHeightInch: 11.69,
      orientation: 'portrait',
      dpi: 300,
      borderless: false,
      rotateBeforePrint: false,
      marginPx: {
        top: 60,
        right: 60,
        bottom: 60,
        left: 60,
      },
      offsetPx: {
        x: 0,
        y: 0,
      },
      scalePercent: 100,
      notes:
        'Generic A4 inkjet profile with safe print margin.',
    });
  };

  const applyA3Preset = () => {
    updatePrinterProfile({
      id: 'custom-a3',
      name: 'A3 Event Poster',
      printerType: 'CUSTOM',
      printerModel: 'Custom A3 Printer',
      paperName: 'A3',
      paperWidthInch: 11.69,
      paperHeightInch: 16.54,
      orientation: 'portrait',
      dpi: 300,
      borderless: false,
      rotateBeforePrint: false,
      marginPx: {
        top: 90,
        right: 90,
        bottom: 90,
        left: 90,
      },
      offsetPx: {
        x: 0,
        y: 0,
      },
      scalePercent: 100,
      notes:
        'A3 layout profile for event poster or custom collage.',
    });
  };

  return (
    <section className="rounded-[2rem] border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Printer
          </p>
          <h3 className="mt-1 text-2xl font-black text-slate-950">
            Printer Profile
          </h3>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Atur profil printer untuk DNP, printer rumahan, margin, offset,
            scale, dan ukuran output print.
          </p>
        </div>

        <button
          type="button"
          onClick={resetPrinterProfile}
          className="rounded-2xl border border-red-200 bg-red-50 px-4 py-2 text-xs font-black text-red-700"
        >
          Reset
        </button>
      </div>

      <div className="mt-5 flex flex-wrap gap-2">
        <button
          type="button"
          onClick={applyDnp4rPreset}
          className="rounded-2xl bg-slate-950 px-4 py-2 text-xs font-black text-white"
        >
          DNP 4R Preset
        </button>

        <button
          type="button"
          onClick={applyInkjetA4Preset}
          className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-black text-slate-700"
        >
          Inkjet A4 Preset
        </button>

        <button
          type="button"
          onClick={applyA3Preset}
          className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-black text-slate-700"
        >
          A3 Preset
        </button>
      </div>

      <div className="mt-5 grid gap-4 lg:grid-cols-2">
        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Profile Name
          </span>
          <input
            value={printerProfile.name}
            onChange={(event) =>
              updatePrinterProfile({
                name: event.target.value,
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Printer Type
          </span>
          <select
            value={printerProfile.printerType}
            onChange={(event) =>
              updatePrinterProfile({
                printerType: event.target.value as PrinterType,
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          >
            <option value="DNP">DNP</option>
            <option value="INKJET">Inkjet</option>
            <option value="GENERIC">Generic</option>
            <option value="CUSTOM">Custom</option>
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Printer Model
          </span>
          <input
            value={printerProfile.printerModel}
            onChange={(event) =>
              updatePrinterProfile({
                printerModel: event.target.value,
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper Name
          </span>
          <input
            value={printerProfile.paperName}
            onChange={(event) =>
              updatePrinterProfile({
                paperName: event.target.value,
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper Width Inch
          </span>
          <input
            type="number"
            step="0.01"
            value={printerProfile.paperWidthInch}
            onChange={(event) =>
              updatePrinterProfile({
                paperWidthInch: toNumber(
                  event.target.value,
                  printerProfile.paperWidthInch,
                ),
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Paper Height Inch
          </span>
          <input
            type="number"
            step="0.01"
            value={printerProfile.paperHeightInch}
            onChange={(event) =>
              updatePrinterProfile({
                paperHeightInch: toNumber(
                  event.target.value,
                  printerProfile.paperHeightInch,
                ),
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Orientation
          </span>
          <select
            value={printerProfile.orientation}
            onChange={(event) =>
              updatePrinterProfile({
                orientation: event.target.value as PrintOrientation,
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          >
            <option value="portrait">Portrait</option>
            <option value="landscape">Landscape</option>
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            DPI
          </span>
          <input
            type="number"
            value={printerProfile.dpi}
            onChange={(event) =>
              updatePrinterProfile({
                dpi: toNumber(event.target.value, printerProfile.dpi),
              })
            }
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          />
        </label>
      </div>

      <div className="mt-5 rounded-3xl bg-slate-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
          Print Calibration
        </p>

        <div className="mt-4 grid gap-4 lg:grid-cols-3">
          <label className="block">
            <span className="text-xs font-black text-slate-400">
              Offset X px
            </span>
            <input
              type="number"
              value={printerProfile.offsetPx.x}
              onChange={(event) =>
                updatePrinterProfile({
                  offsetPx: {
                    x: toNumber(event.target.value, printerProfile.offsetPx.x),
                    y: printerProfile.offsetPx.y,
                  },
                })
              }
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
            />
          </label>

          <label className="block">
            <span className="text-xs font-black text-slate-400">
              Offset Y px
            </span>
            <input
              type="number"
              value={printerProfile.offsetPx.y}
              onChange={(event) =>
                updatePrinterProfile({
                  offsetPx: {
                    x: printerProfile.offsetPx.x,
                    y: toNumber(event.target.value, printerProfile.offsetPx.y),
                  },
                })
              }
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
            />
          </label>

          <label className="block">
            <span className="text-xs font-black text-slate-400">
              Scale %
            </span>
            <input
              type="number"
              step="0.1"
              value={printerProfile.scalePercent}
              onChange={(event) =>
                updatePrinterProfile({
                  scalePercent: toNumber(
                    event.target.value,
                    printerProfile.scalePercent,
                  ),
                })
              }
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
            />
          </label>
        </div>

        <div className="mt-4 grid gap-4 lg:grid-cols-4">
          {(['top', 'right', 'bottom', 'left'] as const).map((side) => (
            <label key={side} className="block">
              <span className="text-xs font-black capitalize text-slate-400">
                Margin {side} px
              </span>
              <input
                type="number"
                value={printerProfile.marginPx[side]}
                onChange={(event) =>
                  updatePrinterProfile({
                    marginPx: {
                      ...printerProfile.marginPx,
                      [side]: toNumber(
                        event.target.value,
                        printerProfile.marginPx[side],
                      ),
                    },
                  })
                }
                className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
              />
            </label>
          ))}
        </div>

        <div className="mt-4 grid gap-3 sm:grid-cols-2">
          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={printerProfile.borderless}
              onChange={(event) =>
                updatePrinterProfile({
                  borderless: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Borderless mode
            </span>
          </label>

          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={printerProfile.rotateBeforePrint}
              onChange={(event) =>
                updatePrinterProfile({
                  rotateBeforePrint: event.target.checked,
                })
              }
            />
            <span className="text-sm font-black text-slate-700">
              Rotate before print
            </span>
          </label>
        </div>
      </div>

      <div className="mt-5 rounded-3xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-blue-400">
          Output Canvas
        </p>
        <p className="mt-2 text-2xl font-black text-blue-950">
          {canvasWidthPx} × {canvasHeightPx} px
        </p>
        <p className="mt-1 text-xs font-bold text-blue-700">
          Based on {printerProfile.paperName}, {printerProfile.orientation},{' '}
          {printerProfile.dpi} DPI.
        </p>
      </div>

      <label className="mt-5 block">
        <span className="text-xs font-black uppercase tracking-wider text-slate-400">
          Notes
        </span>
        <textarea
          value={printerProfile.notes || ''}
          onChange={(event) =>
            updatePrinterProfile({
              notes: event.target.value,
            })
          }
          className="mt-2 min-h-24 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none"
        />
      </label>
    </section>
  );
}
TSX

ADMIN="apps/booth-ui/src/components/AdminPanel.tsx"

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/AdminPanel.tsx")
text = path.read_text()

if "PrinterProfilePanel" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(
        insert_at,
        "import { PrinterProfilePanel } from './admin/PrinterProfilePanel';",
    )
    text = "\n".join(lines) + "\n"

old_placeholder = """          <section className="rounded-[2rem] border border-dashed border-slate-300 bg-white p-5">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Printer
            </p>
            <h3 className="mt-1 text-2xl font-black text-slate-950">
              Printer Profile
            </h3>
            <p className="mt-1 text-sm font-semibold text-slate-500">
              Next: DNP, printer rumahan, margin, offset, scale correction, dan borderless mode.
            </p>
          </section>"""

if old_placeholder in text:
    text = text.replace(old_placeholder, "          <PrinterProfilePanel />", 1)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Phase 10B1B completed."
