# Phase 8B1 - Static QRIS Picker

## Added

- Electron QRIS image picker
- Supported files:
  - PNG
  - JPG/JPEG
  - WebP
- Selected QRIS image is copied into Electron userData brand-assets/qris
- Renderer receives corra-asset://qris/... URL
- Payment Settings Static QRIS can pick local QRIS file
- QRIS preview in Admin Panel

## Usage

In Electron desktop:

1. Open Admin Panel
2. Open Payment Settings
3. Choose Static QRIS PNG
4. Click Pick QRIS PNG/JPG/WebP
5. Select QRIS image
6. QRIS Image URL updates automatically
