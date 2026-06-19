import React, { useEffect, useRef } from 'react';

type CameraLivePreviewProps = {
  stream: MediaStream | null;
  isStarting?: boolean;
  errorMessage?: string;
};

export function CameraLivePreview({
  stream,
  isStarting = false,
  errorMessage = '',
}: CameraLivePreviewProps) {
  const videoRef = useRef<HTMLVideoElement | null>(null);

  useEffect(() => {
    if (!videoRef.current) return;

    videoRef.current.srcObject = stream;
  }, [stream]);

  return (
    <div className="overflow-hidden rounded-[2rem] border border-slate-200 bg-slate-950 shadow-sm">
      <div className="relative aspect-[4/3] w-full">
        {stream ? (
          <video
            ref={videoRef}
            autoPlay
            muted
            playsInline
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center p-6 text-center">
            <div>
              <p className="text-sm font-black uppercase tracking-[0.2em] text-white/40">
                Camera Preview
              </p>
              <p className="mt-2 text-2xl font-black text-white">
                {isStarting ? 'Starting Camera...' : 'No Camera Active'}
              </p>
              <p className="mt-2 text-sm font-semibold text-white/50">
                Start camera untuk menampilkan live preview.
              </p>
            </div>
          </div>
        )}

        {errorMessage && (
          <div className="absolute inset-x-4 bottom-4 rounded-2xl bg-red-500/90 px-4 py-3 text-xs font-bold text-white shadow-lg">
            {errorMessage}
          </div>
        )}
      </div>
    </div>
  );
}
