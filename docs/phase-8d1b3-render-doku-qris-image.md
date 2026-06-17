# Phase 8D1B3 - Render DOKU QRIS as QR Image

## Added

- qrcode package
- QrCodeImage shared component
- PaymentScreen renders DOKU QRIS content as scan-ready QR image

## Behavior

If DOKU response contains QR content, PaymentScreen shows a QR image.
If QR content cannot be detected, PaymentScreen shows the raw DOKU response for debugging.
