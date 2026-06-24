import React, { useState } from 'react';
import {
  listBoothHardwarePrinters,
  printBoothCurrentPage,
} from './booth-hardware-api';
import type { BoothHardwarePrinterInfo } from './booth-hardware-types';
import { upsertBoothHardwareTestRecord } from './booth-hardware-test-storage';

export function BoothPrinterHardwareTestPanel() {
  const [printers, setPrinters] = useState<BoothHardwarePrinterInfo[]>([]);
  const [selectedPrinter, setSelectedPrinter] = useState('');
  const [silent, setSilent] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const refreshPrinters = async () => {
    setMessage('');
    setError('');

    const result = await listBoothHardwarePrinters();
    setPrinters(result.printers);

    if (result.ok) {
      const defaultPrinter = result.printers.find((printer) => printer.isDefault);
      setSelectedPrinter((current) => current || defaultPrinter?.name || result.printers[0]?.name || '');

      upsertBoothHardwareTestRecord({
        label: 'Printer discovery',
        status: result.printers.length > 0 ? 'passed' : 'warning',
        message:
          result.printers.length > 0
            ? `${result.printers.length} printer(s) detected.`
            : 'No printer detected.',
      });

      setMessage(`${result.printers.length} printer(s) detected.`);
    } else {
      upsertBoothHardwareTestRecord({
        label: 'Printer discovery',
        status: 'failed',
        message: result.error,
      });

      setError(result.error || 'Failed to list printers.');
    }
  };

  const runPrintTest = async () => {
    setMessage('');
    setError('');

    const result = await printBoothCurrentPage({
      printerName: selectedPrinter || undefined,
      silent,
      copies: 1,
    });

    upsertBoothHardwareTestRecord({
      label: 'Printer test',
      status: result.ok ? 'passed' : 'failed',
      message: result.ok ? 'Print command accepted.' : result.error,
    });

    if (result.ok) setMessage('Print command accepted.');
    else setError(result.error || 'Print test failed.');
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Printer Hardware Test
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Detect printers and send a print-current-page test.
          </p>
        </div>

        <button
          type="button"
          onClick={() => void refreshPrinters()}
          className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
        >
          Refresh Printers
        </button>
      </div>

      <div className="mt-4 grid gap-3 lg:grid-cols-[1fr_auto]">
        <select
          value={selectedPrinter}
          onChange={(event) => setSelectedPrinter(event.target.value)}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
        >
          <option value="">Default printer / prompt</option>
          {printers.map((printer) => (
            <option key={printer.name} value={printer.name}>
              {printer.displayName || printer.name}
              {printer.isDefault ? ' (default)' : ''}
            </option>
          ))}
        </select>

        <button
          type="button"
          onClick={() => void runPrintTest()}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-3 text-xs font-black text-white"
        >
          Print Test
        </button>
      </div>

      <label className="mt-3 flex items-center gap-2 text-xs font-bold text-white/60">
        <input
          type="checkbox"
          checked={silent}
          onChange={(event) => setSilent(event.target.checked)}
        />
        Silent print if supported
      </label>

      <div className="mt-4 grid gap-2">
        {printers.map((printer) => (
          <div key={printer.name} className="rounded-2xl bg-white/10 p-3">
            <p className="text-xs font-black uppercase text-white">
              {printer.displayName || printer.name}
            </p>
            <p className="mt-1 text-[11px] font-bold text-white/45">
              name={printer.name} · status={printer.status ?? 0}
              {printer.isDefault ? ' · default' : ''}
            </p>
          </div>
        ))}
      </div>

      {message && (
        <div className="mt-4 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">
          {message}
        </div>
      )}

      {error && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          {error}
        </div>
      )}
    </section>
  );
}
