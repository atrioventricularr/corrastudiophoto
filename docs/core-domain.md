# Corra Booth Core Domain

Phase 2 creates the first business-logic skeleton.

## Strict Rules

### Session Mode

Session Mode is timer-based.

The user can generate as many frames as possible while the countdown timer is active.

### Single Mode

Single Mode is frame-count-based.

The user generates a fixed number of frames. Single Mode does not use a countdown timer.

## Image Terms

### Capture

A Capture is one raw photo taken from the camera.

### Frame

A Frame is the final composed image.

One Frame contains 2-8 Captures depending on the selected layout.

### Template

A Template is a full background image.

The Template is placed at the bottom layer. Raw Captures are drawn above the Template based on layout coordinates.

## Platform Boundary

The core package does not know Canon, Sony, DNP, Epson, Supabase, Electron, or Windows.

It only knows ports/interfaces:

- CameraPort
- PrinterPort
- StoragePort
- LicenseRepositoryPort
- ImageComposerPort
- GifGeneratorPort

Concrete implementations come later.
