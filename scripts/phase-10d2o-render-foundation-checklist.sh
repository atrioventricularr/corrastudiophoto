#!/usr/bin/env bash
set -euo pipefail

mkdir -p docs

cat > docs/phase-10-render-foundation-checklist.md <<'MD'
# Phase 10 Render Foundation Checklist

## Status

Phase 10 render foundation is ready for early testing.

## Completed

### Admin Foundation
- Admin sidebar/page mode
- Hardware page
- Billing page
- Layout page
- Template page
- Branding page
- Sessions page

### Printer Foundation
- Printer profile schema
- Printer profile provider
- Printer profile admin panel
- Paper preset selector
- Margin, offset, scale, rotate, borderless settings

### Layout Foundation
- Paper size presets
- Layout slot schema
- Layout provider/local storage
- Active layout selector
- Layout preview canvas
- Layout slot editor
- Layout paper settings
- Guide settings

### Template Foundation
- Template schema
- Template provider/local storage
- Template admin panel
- Create template from active layout
- Duplicate template
- Delete template
- Edit template details
- Template status controls
- Upload/remove frame PNG
- Upload/remove background image
- Layer list
- Layer visibility and opacity
- Template preview canvas
- Asset summary

### Render Foundation
- Raw final render canvas
- Print-ready render canvas
- Printer profile adjustment render
- Raw vs print-ready toggle
- Sample photo upload per slot
- Clear sample photos
- Render status panel
- Render metadata panel
- Download rendered PNG
- Download render metadata JSON
- Calibration guide overlay
- Printer calibration test sheet
- Render history
- Download renders from history

## Next Phase

Return to camera integration:

1. Camera preview mirror toggle
2. Grid overlay
3. Layout slot guide overlay
4. Countdown capture
5. Capture image from camera
6. Assign captured photos to layout slots
7. Render final template using captured photos
8. Export / print-ready output
MD

echo "10D2O checklist created:"
echo "- docs/phase-10-render-foundation-checklist.md"
