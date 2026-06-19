import React, {
  useEffect,
  useState,
} from 'react';
import { useCameraCaptureGuide } from './CameraCaptureGuideProvider';

type CountdownStatus =
  | 'idle'
  | 'counting'
  | 'captured-placeholder';

export function CameraCountdownPanel() {
  const {
    activeStep,
    nextStep,
  } = useCameraCaptureGuide();

  const [countdownSeconds, setCountdownSeconds] = useState(3);
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null);
  const [status, setStatus] = useState<CountdownStatus>('idle');
  const [lastMessage, setLastMessage] = useState('');

  const isCounting = secondsLeft !== null;

  useEffect(() => {
    if (secondsLeft === null) return;

    if (secondsLeft <= 0) {
      setStatus('captured-placeholder');
      setLastMessage(
        activeStep
          ? `Placeholder captured for ${activeStep.label}. Real camera capture will be connected next.`
          : 'Placeholder captured. Real camera capture will be connected next.',
      );
      setSecondsLeft(null);
      return;
    }

    const timer = window.setTimeout(() => {
      setSecondsLeft((current) => {
        if (current === null) return null;
        return current - 1;
      });
    }, 1000);

    return () => window.clearTimeout(timer);
  }, [activeStep, secondsLeft]);

  const handleStartCountdown = () => {
    if (!activeStep) return;

    setStatus('counting');
    setLastMessage('');
    setSecondsLeft(countdownSeconds);
  };

  const handleCancelCountdown = () => {
    setSecondsLeft(null);
    setStatus('idle');
    setLastMessage('Countdown cancelled.');
  };

  const handleNextAfterPlaceholder = () => {
    setStatus('idle');
    setLastMessage('');
    nextStep();
  };

  if (!activeStep) {
    return (
      <section className="rounded-3xl border border-amber-200 bg-amber-50 p-4">
        <p className="text-xs font-black uppercase tracking-[0.2em] text-amber-500">
          Countdown
        </p>
        <p className="mt-2 text-sm font-bold text-amber-800">
          Tidak ada slot aktif untuk countdown.
        </p>
      </section>
    );
  }

  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Countdown Capture
          </p>
          <h4 className="mt-1 text-xl font-black text-slate-950">
            {isCounting ? `${secondsLeft}` : activeStep.label}
          </h4>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Slot {activeStep.index + 1} dari {activeStep.total} ·{' '}
            {activeStep.slot.name}
          </p>
        </div>

        <span className="rounded-full bg-slate-950 px-3 py-1 text-xs font-black uppercase text-white">
          {status}
        </span>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-[1fr_160px]">
        <label className="block">
          <span className="text-xs font-black uppercase tracking-wider text-slate-400">
            Countdown Seconds
          </span>
          <select
            value={countdownSeconds}
            onChange={(event) => setCountdownSeconds(Number(event.target.value))}
            disabled={isCounting}
            className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none disabled:opacity-50"
          >
            <option value={3}>3 seconds</option>
            <option value={5}>5 seconds</option>
            <option value={7}>7 seconds</option>
            <option value={10}>10 seconds</option>
          </select>
        </label>

        <div className="flex items-end">
          {isCounting ? (
            <button
              type="button"
              onClick={handleCancelCountdown}
              className="w-full rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-black text-red-700"
            >
              Cancel
            </button>
          ) : (
            <button
              type="button"
              onClick={handleStartCountdown}
              className="w-full rounded-2xl bg-blue-600 px-4 py-3 text-xs font-black text-white"
            >
              Start Countdown
            </button>
          )}
        </div>
      </div>

      {isCounting && (
        <div className="mt-4 rounded-3xl bg-blue-50 p-6 text-center">
          <p className="text-7xl font-black text-blue-700">
            {secondsLeft}
          </p>
          <p className="mt-2 text-xs font-black uppercase tracking-[0.2em] text-blue-400">
            Get Ready
          </p>
        </div>
      )}

      {lastMessage && (
        <div className="mt-4 rounded-2xl bg-slate-50 p-3 text-sm font-bold text-slate-600">
          {lastMessage}
        </div>
      )}

      {status === 'captured-placeholder' && (
        <button
          type="button"
          onClick={handleNextAfterPlaceholder}
          className="mt-4 w-full rounded-2xl bg-slate-950 px-4 py-3 text-xs font-black text-white"
        >
          Continue to Next Pose
        </button>
      )}
    </section>
  );
}
