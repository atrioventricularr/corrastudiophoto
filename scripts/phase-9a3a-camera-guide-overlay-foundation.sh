#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A3A - Camera Guide Overlay"
echo "========================================"

mkdir -p apps/booth-ui/src/camera

cat > apps/booth-ui/src/camera/CameraGuideOverlay.tsx <<'TSX'
import React from 'react';
import { useLayouts } from '../layouts';

export function CameraGuideOverlay() {
  const {
    activeLayout,
    guideSettings,
  } = useLayouts();

  const opacity = guideSettings.guideOpacity;

  if (!guideSettings.showGrid && !guideSettings.showSlotGuide) {
    return null;
  }

  return (
    <div
      className="pointer-events-none absolute inset-0 z-20 overflow-hidden rounded-[inherit]"
      style={{
        opacity,
      }}
    >
      {guideSettings.showGrid && (
        <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.35)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.35)_1px,transparent_1px)] bg-[size:10%_10%]" />
      )}

      {guideSettings.showSlotGuide &&
        activeLayout.slots
          .filter((slot) => slot.showGuide)
          .map((slot) => (
            <div
              key={slot.id}
              className="absolute flex items-center justify-center border-2 border-dashed border-white bg-black/15 text-center shadow-[0_0_0_1px_rgba(0,0,0,0.25)]"
              style={{
                left: `${slot.xPercent}%`,
                top: `${slot.yPercent}%`,
                width: `${slot.widthPercent}%`,
                height: `${slot.heightPercent}%`,
                borderRadius:
                  slot.shape === 'circle'
                    ? '9999px'
                    : `${slot.borderRadiusPercent}%`,
                transform: `rotate(${slot.rotationDeg}deg)`,
              }}
            >
              <div className="rounded-full bg-black/55 px-3 py-1">
                <p className="text-[10px] font-black uppercase tracking-wider text-white">
                  {slot.guideLabel || slot.name}
                </p>
                <p className="mt-0.5 font-mono text-[9px] font-bold text-white/75">
                  #{slot.captureOrder}
                </p>
              </div>
            </div>
          ))}
    </div>
  );
}
TSX

grep -q "CameraGuideOverlay" apps/booth-ui/src/camera/index.ts 2>/dev/null || cat >> apps/booth-ui/src/camera/index.ts <<'TS'
export * from './CameraGuideOverlay';
TS

FILE="apps/booth-ui/src/camera/CameraLivePreview.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: $FILE not found."
  echo "CameraGuideOverlay component was created, but CameraLivePreview was not patched."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/camera/CameraLivePreview.tsx")
text = path.read_text()

# Add import.
if "CameraGuideOverlay" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { CameraGuideOverlay } from './CameraGuideOverlay';")
    text = "\n".join(lines) + "\n"

# Ensure the preview wrapper has relative positioning.
text = text.replace(
    'className="overflow-hidden',
    'className="relative overflow-hidden',
    1,
)

text = text.replace(
    "className='overflow-hidden",
    "className='relative overflow-hidden",
    1,
)

# Insert overlay after first self-closing video tag.
if "<CameraGuideOverlay />" not in text:
    pattern = re.compile(r"(<video[\s\S]*?\/>)", re.MULTILINE)
    match = pattern.search(text)

    if match:
        text = text[:match.end()] + "\n      <CameraGuideOverlay />" + text[match.end():]
    else:
        raise SystemExit("Could not find self-closing <video /> tag. Patch manually by placing <CameraGuideOverlay /> inside the preview container above overlays/buttons.")

path.write_text(text)
print("PATCH:", path)
PY

echo ""
echo "Relevant lines:"
grep -n "CameraGuideOverlay\\|relative overflow-hidden\\|video" "$FILE" || true

echo ""
echo "9A3A done."
