#!/usr/bin/env bash
set -euo pipefail

FILE="apps/booth-ui/src/camera/CameraCountdownPanel.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found. Run 9A3H first."
  exit 1
}

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/camera/CameraCountdownPanel.tsx")
text = path.read_text()

# 1. Add auto-advance states.
old = """  const [capturedFrame, setCapturedFrame] =
    useState<CameraFrameCaptureResult | null>(null);"""

new = """  const [capturedFrame, setCapturedFrame] =
    useState<CameraFrameCaptureResult | null>(null);
  const [autoAdvanceAfterCapture, setAutoAdvanceAfterCapture] =
    useState(false);
  const [autoAdvanceDelayMs, setAutoAdvanceDelayMs] = useState(1500);"""

if "autoAdvanceAfterCapture" not in text:
    if old not in text:
        raise SystemExit("Could not find capturedFrame state block.")
    text = text.replace(old, new, 1)

# 2. Add auto-advance effect before handleStartCountdown.
marker = """  const handleStartCountdown = () => {"""

effect = """  useEffect(() => {
    if (status !== 'captured' || !autoAdvanceAfterCapture || !capturedFrame) {
      return;
    }

    const timer = window.setTimeout(() => {
      setStatus('idle');
      setLastMessage('');
      setCapturedFrame(null);
      nextStep();
    }, autoAdvanceDelayMs);

    return () => window.clearTimeout(timer);
  }, [
    autoAdvanceAfterCapture,
    autoAdvanceDelayMs,
    capturedFrame,
    nextStep,
    status,
  ]);

"""

if "window.setTimeout(() => {" not in text or "autoAdvanceDelayMs" not in text.split("const handleStartCountdown", 1)[0]:
    if marker not in text:
        raise SystemExit("Could not find handleStartCountdown marker.")
    text = text.replace(marker, effect + marker, 1)

# 3. Add UI setting before countdown visual.
marker = """      {isCounting && ("""

ui = """      <div className="mt-4 rounded-2xl border border-blue-100 bg-blue-50 p-4">
        <div className="grid gap-3 sm:grid-cols-[1fr_180px] sm:items-end">
          <label className="flex items-center gap-3 rounded-2xl bg-white px-4 py-3">
            <input
              type="checkbox"
              checked={autoAdvanceAfterCapture}
              onChange={(event) =>
                setAutoAdvanceAfterCapture(event.target.checked)
              }
            />
            <span className="text-sm font-black text-blue-900">
              Auto-advance after capture
            </span>
          </label>

          <label className="block">
            <span className="text-xs font-black uppercase tracking-wider text-blue-400">
              Delay
            </span>
            <select
              value={autoAdvanceDelayMs}
              onChange={(event) =>
                setAutoAdvanceDelayMs(Number(event.target.value))
              }
              disabled={!autoAdvanceAfterCapture}
              className="mt-2 w-full rounded-2xl border border-blue-100 bg-white px-4 py-3 text-sm font-bold text-blue-900 outline-none disabled:opacity-50"
            >
              <option value={1000}>1 sec</option>
              <option value={1500}>1.5 sec</option>
              <option value={2000}>2 sec</option>
              <option value={3000}>3 sec</option>
            </select>
          </label>
        </div>
      </div>

"""

if "Auto-advance after capture" not in text:
    if marker not in text:
        raise SystemExit("Could not find countdown visual marker.")
    text = text.replace(marker, ui + marker, 1)

# 4. Add auto-advance note after captured frame if not present.
old = """      {status === 'captured' && (
        <div className="mt-4 grid gap-3 sm:grid-cols-2">"""

new = """      {status === 'captured' && autoAdvanceAfterCapture && (
        <div className="mt-4 rounded-2xl bg-blue-50 p-3 text-sm font-bold text-blue-700">
          Auto-advancing to next pose...
        </div>
      )}

      {status === 'captured' && (
        <div className="mt-4 grid gap-3 sm:grid-cols-2">"""

if "Auto-advancing to next pose" not in text:
    if old not in text:
        raise SystemExit("Could not find captured action block.")
    text = text.replace(old, new, 1)

path.write_text(text)
print("9A3J patched:", path)
PY

echo "9A3J done."
