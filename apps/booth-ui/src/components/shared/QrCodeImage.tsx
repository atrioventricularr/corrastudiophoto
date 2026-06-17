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
