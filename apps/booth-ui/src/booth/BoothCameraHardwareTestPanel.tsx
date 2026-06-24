import React, { useRef, useState } from 'react';
import { upsertBoothHardwareTestRecord } from './booth-hardware-test-storage';

type CameraDevice = {
  deviceId: string;
  label: string;
  kind: string;
};

export function BoothCameraHardwareTestPanel() {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const currentStreamRef = useRef<MediaStream | null>(null);
  const [devices, setDevices] = useState<CameraDevice[]>([]);
  const [selectedDeviceId, setSelectedDeviceId] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const stopCurrentStream = () => {
    currentStreamRef.current?.getTracks().forEach((track) => track.stop());
    currentStreamRef.current = null;
  };

  const refreshCameras = async () => {
    setMessage('');
    setError('');

    try {
      await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
      const allDevices = await navigator.mediaDevices.enumerateDevices();
      const cameras = allDevices
        .filter((device) => device.kind === 'videoinput')
        .map((device, index) => ({
          deviceId: device.deviceId,
          kind: device.kind,
          label: device.label || `Camera ${index + 1}`,
        }));

      setDevices(cameras);
      setSelectedDeviceId((current) => current || cameras[0]?.deviceId || '');

      upsertBoothHardwareTestRecord({
        label: 'Camera discovery',
        status: cameras.length > 0 ? 'passed' : 'failed',
        message:
          cameras.length > 0
            ? `${cameras.length} camera(s) detected.`
            : 'No camera detected.',
      });

      setMessage(`${cameras.length} camera(s) detected.`);
    } catch (caughtError) {
      const nextError =
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to access camera.';

      upsertBoothHardwareTestRecord({
        label: 'Camera discovery',
        status: 'failed',
        message: nextError,
      });

      setError(nextError);
    }
  };

  const startPreview = async () => {
    setMessage('');
    setError('');

    try {
      stopCurrentStream();

      const stream = await navigator.mediaDevices.getUserMedia({
        video: selectedDeviceId
          ? { deviceId: { exact: selectedDeviceId } }
          : true,
        audio: false,
      });

      currentStreamRef.current = stream;

      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        await videoRef.current.play();
      }

      upsertBoothHardwareTestRecord({
        label: 'Camera preview',
        status: 'passed',
        message: 'Camera preview started.',
      });

      setMessage('Camera preview started.');
    } catch (caughtError) {
      const nextError =
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to start camera preview.';

      upsertBoothHardwareTestRecord({
        label: 'Camera preview',
        status: 'failed',
        message: nextError,
      });

      setError(nextError);
    }
  };

  return (
    <section className="rounded-3xl border border-white/10 bg-black/20 p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-white/40">
            Camera Hardware Test
          </p>
          <p className="mt-1 text-sm font-bold text-white/60">
            Detect cameras and start a live preview.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => void refreshCameras()}
            className="rounded-2xl bg-white px-3 py-2 text-xs font-black text-slate-950"
          >
            Refresh Cameras
          </button>

          <button
            type="button"
            onClick={stopCurrentStream}
            className="rounded-2xl border border-white/15 bg-white/10 px-3 py-2 text-xs font-black text-white"
          >
            Stop
          </button>
        </div>
      </div>

      <div className="mt-4 grid gap-3 lg:grid-cols-[1fr_auto]">
        <select
          value={selectedDeviceId}
          onChange={(event) => setSelectedDeviceId(event.target.value)}
          className="rounded-2xl bg-white px-3 py-3 text-xs font-black text-slate-950"
        >
          <option value="">Default camera</option>
          {devices.map((device) => (
            <option key={device.deviceId} value={device.deviceId}>
              {device.label}
            </option>
          ))}
        </select>

        <button
          type="button"
          onClick={() => void startPreview()}
          className="rounded-2xl border border-white/15 bg-white/10 px-3 py-3 text-xs font-black text-white"
        >
          Start Preview
        </button>
      </div>

      <div className="mt-4 overflow-hidden rounded-3xl border border-white/10 bg-black">
        <video
          ref={videoRef}
          muted
          playsInline
          className="aspect-video w-full object-contain"
        />
      </div>

      {message && (
        <div className="mt-4 rounded-2xl bg-emerald-500/20 p-3 text-xs font-bold text-emerald-100">
          {message}
        </div>
      )}

      {error && (
        <div className="mt-4 rounded-2xl border border-red-300/30 bg-red-500/20 p-3 text-xs font-bold text-red-100">
          {error}
        </div>
      )}
    </section>
  );
}
