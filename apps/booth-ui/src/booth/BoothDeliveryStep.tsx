import React, { useState } from 'react';
import {
  isCameraPrintBridgeAvailable,
  printImageThroughBridge,
  useCameraPrintQueue,
  useCameraRenderOutput,
} from '../camera';
import { useBoothFlow } from './BoothFlowProvider';

function downloadDataUrl(input: {
  dataUrl: string;
  templateName: string;
  renderMode: string;
}) {
  const safeTemplateName = input.templateName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');

  const link = document.createElement('a');
  link.href = input.dataUrl;
  link.download = `${safeTemplateName || 'corra-booth'}-${input.renderMode}-final.png`;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

export function BoothDeliveryStep() {
  const { setStep, completeSession } = useBoothFlow();
  const {
    selectedOutput,
    printCandidateOutput,
    markSelectedOutputAsPrintCandidate,
  } = useCameraRenderOutput();

  const {
    enqueuePrintJob,
    updatePrintJobStatus,
    latestPrintJob,
  } = useCameraPrintQueue();

  const [copies, setCopies] = useState(1);
  const [isPrinting, setIsPrinting] = useState(false);
  const [message, setMessage] = useState('');

  const bridgeAvailable = isCameraPrintBridgeAvailable();
  const outputForDelivery = printCandidateOutput || selectedOutput;

  const handleDownload = () => {
    if (!outputForDelivery) return;

    downloadDataUrl({
      dataUrl: outputForDelivery.dataUrl,
      templateName: outputForDelivery.templateName,
      renderMode: outputForDelivery.renderMode,
    });

    setMessage('Final output downloaded.');
  };

  const handleCreatePrintJob = () => {
    if (!outputForDelivery) return;

    if (!printCandidateOutput) {
      markSelectedOutputAsPrintCandidate();
    }

    const job = enqueuePrintJob({
      output: outputForDelivery,
      copies,
    });

    setMessage(`Print job created: ${job.copies} copy/copies.`);
  };

  const handlePrintNow = async () => {
    if (!outputForDelivery) return;

    if (!printCandidateOutput) {
      markSelectedOutputAsPrintCandidate();
    }

    const job = enqueuePrintJob({
      output: outputForDelivery,
      copies,
    });

    setIsPrinting(true);
    setMessage('Sending print job...');

    updatePrintJobStatus(job.id, 'printing');

    const result = await printImageThroughBridge({
      jobId: job.id,
      dataUrl: job.dataUrl,
      widthPx: job.widthPx,
      heightPx: job.heightPx,
      copies: job.copies,
      templateName: job.templateName,
      renderMode: job.renderMode,
      silent: false,
    });

    if (result.ok) {
      updatePrintJobStatus(job.id, 'completed', {
        printerName: result.printerName,
        resultMessage: result.message || 'Print sent successfully.',
      });
      setMessage(result.message || 'Print sent successfully.');
    } else {
      updatePrintJobStatus(job.id, 'failed', {
        printerName: result.printerName,
        errorMessage: result.error || 'Print failed.',
      });
      setMessage(result.error || 'Print failed.');
    }

    setIsPrinting(false);
  };

  const handleFinish = () => {
    completeSession();
  };

  if (!outputForDelivery) {
    return (
      <div className="mt-4 rounded-[2rem] bg-white p-6 text-slate-950">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-amber-500">
          Delivery
        </p>
        <h4 className="mt-3 text-5xl font-black leading-none">
          No Final Output
        </h4>
        <p className="mt-4 text-sm font-bold text-slate-600">
          Belum ada final output untuk delivery. Kembali ke Review untuk render
          hasil foto.
        </p>

        <button
          type="button"
          onClick={() => setStep('review')}
          className="mt-6 rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
        >
          Back to Review
        </button>
      </div>
    );
  }

  return (
    <div className="mt-4 grid gap-6 xl:grid-cols-[1.1fr_0.9fr]">
      <section className="rounded-[2rem] border border-white/10 bg-white/10 p-6">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-white/50">
          Final Output
        </p>

        <div className="mt-5 flex min-h-[520px] items-center justify-center rounded-[2rem] bg-black/20 p-4">
          <img
            src={outputForDelivery.dataUrl}
            alt="Final delivery output"
            className="max-h-[500px] rounded-3xl border border-white/10 bg-white object-contain"
          />
        </div>

        <div className="mt-4 grid gap-3 sm:grid-cols-3">
          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-xs font-black uppercase text-white/40">
              Size
            </p>
            <p className="mt-1 text-sm font-black text-white">
              {outputForDelivery.widthPx} × {outputForDelivery.heightPx}px
            </p>
          </div>

          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-xs font-black uppercase text-white/40">
              Mode
            </p>
            <p className="mt-1 text-sm font-black text-white">
              {outputForDelivery.renderMode}
            </p>
          </div>

          <div className="rounded-3xl bg-white/10 p-4">
            <p className="text-xs font-black uppercase text-white/40">
              Bridge
            </p>
            <p className="mt-1 text-sm font-black text-white">
              {bridgeAvailable ? 'Ready' : 'Missing'}
            </p>
          </div>
        </div>
      </section>

      <aside className="rounded-[2rem] bg-white p-6 text-slate-950">
        <p className="text-xs font-black uppercase tracking-[0.25em] text-blue-500">
          Delivery
        </p>

        <h4 className="mt-3 text-5xl font-black leading-none">
          Print or Download
        </h4>

        <p className="mt-4 text-sm font-bold leading-relaxed text-slate-600">
          Pilih cara menerima hasil akhir. Untuk development, print bridge hanya
          benar-benar jalan saat app dibuka lewat Electron.
        </p>

        <div className="mt-6 rounded-3xl bg-slate-50 p-4">
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Copies
          </p>

          <select
            value={copies}
            onChange={(event) => setCopies(Number(event.target.value))}
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-bold text-slate-800 outline-none"
          >
            <option value={1}>1 copy</option>
            <option value={2}>2 copies</option>
            <option value={3}>3 copies</option>
            <option value={4}>4 copies</option>
            <option value={5}>5 copies</option>
          </select>
        </div>

        {!bridgeAvailable && (
          <div className="mt-4 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm font-bold text-amber-800">
            Print bridge belum tersedia. Kalau di browser/Codespaces, pakai
            Download atau Create Print Job dulu. Real print diuji di Electron.
          </div>
        )}

        <div className="mt-6 grid gap-3">
          <button
            type="button"
            onClick={handleDownload}
            className="rounded-3xl bg-blue-600 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
          >
            Download Final PNG
          </button>

          <button
            type="button"
            onClick={handleCreatePrintJob}
            className="rounded-3xl border border-slate-200 bg-white px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            Create Print Job
          </button>

          <button
            type="button"
            onClick={() => void handlePrintNow()}
            disabled={isPrinting}
            className="rounded-3xl bg-slate-950 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white disabled:opacity-40"
          >
            {isPrinting ? 'Printing...' : 'Print Now'}
          </button>

          <button
            type="button"
            onClick={() => setStep('review')}
            className="rounded-3xl border border-slate-200 bg-slate-50 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-slate-700"
          >
            Back to Review
          </button>

          <button
            type="button"
            onClick={handleFinish}
            className="rounded-3xl bg-emerald-600 px-5 py-4 text-xs font-black uppercase tracking-[0.15em] text-white"
          >
            Finish Session
          </button>
        </div>

        {message && (
          <div className="mt-4 rounded-2xl bg-slate-50 p-3 text-sm font-bold text-slate-700">
            {message}
          </div>
        )}

        {latestPrintJob && (
          <div className="mt-4 rounded-3xl bg-slate-50 p-4">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
              Latest Print Job
            </p>
            <p className="mt-2 text-sm font-black text-slate-950">
              {latestPrintJob.status.toUpperCase()} · {latestPrintJob.copies}{' '}
              copy{latestPrintJob.copies > 1 ? 'ies' : ''}
            </p>

            {latestPrintJob.printerName && (
              <p className="mt-1 text-xs font-bold text-blue-700">
                Printer: {latestPrintJob.printerName}
              </p>
            )}

            {latestPrintJob.errorMessage && (
              <p className="mt-1 text-xs font-bold text-red-700">
                {latestPrintJob.errorMessage}
              </p>
            )}
          </div>
        )}
      </aside>
    </div>
  );
}
