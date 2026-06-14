# Corra Booth Image Engine

Phase 3 creates the image-engine skeleton.

## Responsibility

The image engine is responsible for:

- Building composition layers
- Drawing the template background at the bottom layer
- Drawing raw captures above the template
- Transforming layout slots into draw operations
- Exporting the final frame
- Generating GIF assets
- Building download URLs
- Generating QR code data URLs

## Layering Rule

Strict order:

1. Template/background image
2. Raw capture 1
3. Raw capture 2
4. Raw capture 3
5. Raw capture etc.

The template is a full background image. It is not assumed to be a transparent PNG.

## Current Phase

This phase uses placeholder/mock adapters:

- `InMemoryCanvasAdapter`
- `MockGifRenderer`
- `PlaceholderQrCodeGenerator`

These exist so the app can typecheck and the architecture can be tested before adding heavy native dependencies.

## Later Implementation Options

For Windows/Electron production:

- `sharp`
- `canvas`
- `jimp`
- native printer pipeline
- FFmpeg/GIF renderer if needed

For browser/mobile:

- HTML Canvas
- OffscreenCanvas
- WebCodecs where available
- Capacitor filesystem for local assets

## Important Boundary

The image engine must not depend on Electron, Canon SDK, Sony SDK, DNP SDK, Mayar, or Supabase service-role keys.
