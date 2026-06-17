#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 8D1B3 - Render DOKU QRIS Image"
echo "========================================"

FILE="apps/booth-ui/src/components/PaymentScreen.tsx"

[ -f "$FILE" ] || {
  echo "ERROR: PaymentScreen.tsx not found."
  exit 1
}

grep -q "dokuQrisText" "$FILE" || {
  echo "ERROR: dokuQrisText not found. Run 8D1B2 first."
  exit 1
}

echo ""
echo "Installing qrcode package..."

pnpm --filter @corra/booth-ui add qrcode
pnpm --filter @corra/booth-ui add -D @types/qrcode

echo ""
echo "Writing QrCodeImage component..."

mkdir -p apps/booth-ui/src/components/shared

cat > apps/booth-ui/src/components/shared/QrCodeImage.tsx <<'TSX'
import React, { useEffect, useState } from 'react';
import QRCode from 'qrcode';

type QrCodeImageProps = {
  value: string;
  size?: number;
  alt?: string;
  className?: string;
};

export default function QrCodeImage({
  value,
  size = 240,
  alt = 'QR Code',
  className = '',
}: QrCodeImageProps) {
  const [dataUrl, setDataUrl] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    let cancelled = false;

    async function generateQrCode() {
      setErrorMessage('');
      setDataUrl('');

      if (!value) {
        return;
      }

      try {
        const nextDataUrl = await QRCode.toDataURL(value, {
          errorCorrectionLevel: 'M',
          margin: 2,
          width: size,
        });

        if (!cancelled) {
          setDataUrl(nextDataUrl);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorMessage(
            error instanceof Error
              ? error.message
              : 'Failed to generate QR image.',
          );
        }
      }
    }

    generateQrCode();

    return () => {
      cancelled = true;
    };
  }, [size, value]);

  if (errorMessage) {
    return (
      <div className="rounded-2xl border border-red-200 bg-red-50 p-4 text-xs font-bold text-red-700">
        {errorMessage}
      </div>
    );
  }

  if (!dataUrl) {
    return (
      <div
        className={`flex items-center justify-center rounded-2xl border border-[var(--corra-border)] bg-white ${className}`}
        style={{
          width: size,
          height: size,
        }}
      >
        <div className="h-8 w-8 rounded-full border-4 border-[var(--corra-primary)] border-t-transparent animate-spin" />
      </div>
    );
  }

  return (
    <img
      src={dataUrl}
      alt={alt}
      width={size}
      height={size}
      className={className}
    />
  );
}
TSX

echo ""
echo "Patching PaymentScreen..."

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/components/PaymentScreen.tsx")
text = path.read_text()

if "QrCodeImage" not in text:
    text = text.replace(
        "import { AdminSettings } from '../types';",
        "import { AdminSettings } from '../types';\nimport QrCodeImage from './shared/QrCodeImage';"
    )

old_block = """                    {dokuQrisText ? (
                      <div className="mt-3 rounded-xl bg-white p-3">
                        <p className="mb-1 font-black">QR Content</p>
                        <p className="break-all font-mono text-[10px]">
                          {dokuQrisText}
                        </p>
                      </div>
                    ) : (
                      <div className="mt-3 rounded-xl bg-white p-3">
                        <p className="font-black">Raw DOKU Response</p>
                        <pre className="mt-2 max-h-36 overflow-auto whitespace-pre-wrap text-[10px]">
                          {JSON.stringify(dokuQrisResult.doku, null, 2)}
                        </pre>
                      </div>
                    )}"""

new_block = """                    {dokuQrisText ? (
                      <div className="mt-3 rounded-2xl bg-white p-4 text-center">
                        <p className="mb-3 font-black">Scan QRIS</p>

                        <div className="mx-auto flex w-fit rounded-2xl border border-[var(--corra-border)] bg-white p-3 shadow-sm">
                          <QrCodeImage
                            value={dokuQrisText}
                            size={220}
                            alt="DOKU QRIS"
                            className="rounded-xl bg-white object-contain"
                          />
                        </div>

                        <details className="mt-3 text-left">
                          <summary className="cursor-pointer text-xs font-black">
                            Show QR Content
                          </summary>
                          <p className="mt-2 break-all rounded-xl bg-stone-50 p-3 font-mono text-[10px] text-stone-600">
                            {dokuQrisText}
                          </p>
                        </details>
                      </div>
                    ) : (
                      <div className="mt-3 rounded-xl bg-white p-3">
                        <p className="font-black">Raw DOKU Response</p>
                        <pre className="mt-2 max-h-36 overflow-auto whitespace-pre-wrap text-[10px]">
                          {JSON.stringify(dokuQrisResult.doku, null, 2)}
                        </pre>
                      </div>
                    )}"""

if old_block not in text:
    raise SystemExit("Could not find old DOKU QR content block.")

text = text.replace(old_block, new_block)

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Writing docs..."

mkdir -p docs

cat > docs/phase-8d1b3-render-doku-qris-image.md <<'MD'
# Phase 8D1B3 - Render DOKU QRIS as QR Image

## Added

- qrcode package
- QrCodeImage shared component
- PaymentScreen renders DOKU QRIS content as scan-ready QR image

## Behavior

If DOKU response contains QR content, PaymentScreen shows a QR image.
If QR content cannot be detected, PaymentScreen shows the raw DOKU response for debugging.
MD

echo ""
echo "Verifying..."

grep -q "QrCodeImage" "$FILE" || {
  echo "ERROR: PaymentScreen missing QrCodeImage."
  exit 1
}

[ -f "apps/booth-ui/src/components/shared/QrCodeImage.tsx" ] || {
  echo "ERROR: QrCodeImage component missing."
  exit 1
}

echo ""
echo "Phase 8D1B3 completed."
