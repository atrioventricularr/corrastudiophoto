#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8E1B2A - Connect Session Main Flow"
echo "========================================"

FILE="apps/booth-ui/src/App.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: App.tsx not found."
  exit 1
}

[ -f "apps/booth-ui/src/sessions/index.ts" ] || {
  echo "ERROR: sessions module not found. Run 8E1A first."
  exit 1
}

python - <<'PY'
from pathlib import Path
import re

path = Path("apps/booth-ui/src/App.tsx")
text = path.read_text()

# Ensure import exists
if "useSessionLifecycle" not in text:
    lines = text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, "import { useSessionLifecycle } from './sessions';")
    text = "\n".join(lines) + "\n"

# Ensure hook exists
if "transitionBoothSession" not in text:
    match = re.search(r"(export default function App\(\)\s*\{\n|function App\(\)\s*\{\n)", text)
    if not match:
        raise SystemExit("Could not find App function opening.")

    hook = """  const {
    startBoothSession,
    transitionBoothSession,
    cancelBoothSession,
  } = useSessionLifecycle();

"""
    text = text[:match.end()] + hook + text[match.end():]

def patch_handler(handler_names, patch_text, marker):
    global text
    if marker in text:
        return

    for name in handler_names:
        pattern = rf"(const {name}\s*=\s*\(([^)]*)\)\s*=>\s*\{{\n)([\s\S]*?)(\n\s*\}};)"
        match = re.search(pattern, text)

        if match:
            body_start = match.start(3)
            text = text[:body_start] + patch_text + text[body_start:]
            print(f"PATCH handler: {name}")
            return

    print(f"WARN: could not find handler for marker {marker}")

# Layout selected
patch_handler(
    ["handleLayoutSelect", "handleLayoutSelected", "handleSelectLayout", "onLayoutSelect"],
    """    transitionBoothSession({
      toStatus: 'layout_selected',
      reason: 'layout_selected_by_customer',
      metadata: {
        step: 'layout_selection',
      },
    });

""",
    "layout_selected_by_customer",
)

# Template selected
patch_handler(
    ["handleTemplateSelect", "handleTemplateSelected", "handleSelectTemplate", "onTemplateSelect"],
    """    transitionBoothSession({
      toStatus: 'template_selected',
      reason: 'template_selected_by_customer',
      metadata: {
        step: 'template_selection',
      },
    });

""",
    "template_selected_by_customer",
)

# Capture start
patch_handler(
    ["handleStartCapture", "handleCameraStart", "handleCaptureStart", "onCaptureStart"],
    """    transitionBoothSession({
      toStatus: 'capturing',
      reason: 'capture_started',
      metadata: {
        step: 'camera_capture',
      },
    });

""",
    "capture_started",
)

# Capture complete
patch_handler(
    ["handleCaptureComplete", "handlePhotosCaptured", "handlePhotoCaptureComplete", "onCaptureComplete"],
    """    transitionBoothSession({
      toStatus: 'captured',
      reason: 'photos_captured',
      metadata: {
        step: 'capture_complete',
      },
    });

""",
    "photos_captured",
)

# Processing start
patch_handler(
    ["handleProcessingStart", "handleStartProcessing", "onProcessingStart"],
    """    transitionBoothSession({
      toStatus: 'processing',
      reason: 'image_processing_started',
      metadata: {
        step: 'processing',
      },
    });

""",
    "image_processing_started",
)

# Processing complete
patch_handler(
    ["handleProcessingComplete", "handleImageProcessed", "handleResultReady", "onProcessingComplete"],
    """    transitionBoothSession({
      toStatus: 'completed',
      reason: 'image_processing_completed',
      metadata: {
        step: 'result_ready',
      },
    });

""",
    "image_processing_completed",
)

# Delivered / finish / new session
patch_handler(
    ["handleFinishSession", "handleNewSession", "handleRestart", "handleDone", "onFinish"],
    """    transitionBoothSession({
      toStatus: 'delivered',
      reason: 'session_delivered_to_customer',
      metadata: {
        step: 'result_delivered',
      },
    });

""",
    "session_delivered_to_customer",
)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Relevant lifecycle lines:"
grep -n "layout_selected_by_customer\\|template_selected_by_customer\\|capture_started\\|photos_captured\\|image_processing_started\\|image_processing_completed\\|session_delivered_to_customer\\|useSessionLifecycle\\|transitionBoothSession" "$FILE" || true

echo ""
echo "Phase 8E1B2A completed."
