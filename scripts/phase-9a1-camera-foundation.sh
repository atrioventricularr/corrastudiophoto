#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 9A1 - Camera Foundation"
echo "========================================"

mkdir -p apps/booth-ui/src/camera
mkdir -p apps/booth-ui/src/components/camera

cat > apps/booth-ui/src/camera/types.ts <<'TS'
export type CameraPermissionStatus =
  | 'idle'
  | 'requesting'
  | 'granted'
  | 'denied'
  | 'unsupported'
  | 'error';

export type CameraDevice = {
  deviceId: string;
  label: string;
  groupId?: string;
};

export type CameraStreamState = {
  permissionStatus: CameraPermissionStatus;
  devices: CameraDevice[];
  selectedDeviceId: string;
  stream: MediaStream | null;
  errorMessage: string;
  isLoadingDevices: boolean;
  isStartingCamera: boolean;
};
TS

cat > apps/booth-ui/src/camera/useCameraDevices.ts <<'TS'
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { CameraDevice, CameraPermissionStatus } from './types';

function isCameraSupported(): boolean {
  return Boolean(
    typeof navigator !== 'undefined' &&
      navigator.mediaDevices &&
      navigator.mediaDevices.getUserMedia &&
      navigator.mediaDevices.enumerateDevices,
  );
}

function normalizeVideoDevices(devices: MediaDeviceInfo[]): CameraDevice[] {
  return devices
    .filter((device) => device.kind === 'videoinput')
    .map((device, index) => ({
      deviceId: device.deviceId,
      groupId: device.groupId,
      label: device.label || `Camera ${index + 1}`,
    }));
}

export function useCameraDevices() {
  const streamRef = useRef<MediaStream | null>(null);

  const [permissionStatus, setPermissionStatus] =
    useState<CameraPermissionStatus>('idle');
  const [devices, setDevices] = useState<CameraDevice[]>([]);
  const [selectedDeviceId, setSelectedDeviceId] = useState('');
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [errorMessage, setErrorMessage] = useState('');
  const [isLoadingDevices, setIsLoadingDevices] = useState(false);
  const [isStartingCamera, setIsStartingCamera] = useState(false);

  const stopCamera = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => {
        track.stop();
      });
    }

    streamRef.current = null;
    setStream(null);
  }, []);

  const loadDevices = useCallback(async () => {
    if (!isCameraSupported()) {
      setPermissionStatus('unsupported');
      setErrorMessage('Camera API is not supported in this environment.');
      return [];
    }

    setIsLoadingDevices(true);
    setErrorMessage('');

    try {
      const mediaDevices = await navigator.mediaDevices.enumerateDevices();
      const videoDevices = normalizeVideoDevices(mediaDevices);

      setDevices(videoDevices);

      if (!selectedDeviceId && videoDevices[0]?.deviceId) {
        setSelectedDeviceId(videoDevices[0].deviceId);
      }

      return videoDevices;
    } catch (error) {
      setPermissionStatus('error');
      setErrorMessage(
        error instanceof Error ? error.message : 'Failed to load cameras.',
      );
      return [];
    } finally {
      setIsLoadingDevices(false);
    }
  }, [selectedDeviceId]);

  const requestPermission = useCallback(async () => {
    if (!isCameraSupported()) {
      setPermissionStatus('unsupported');
      setErrorMessage('Camera API is not supported in this environment.');
      return false;
    }

    setPermissionStatus('requesting');
    setErrorMessage('');

    try {
      const temporaryStream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: false,
      });

      temporaryStream.getTracks().forEach((track) => track.stop());

      setPermissionStatus('granted');
      await loadDevices();

      return true;
    } catch (error) {
      setPermissionStatus('denied');
      setErrorMessage(
        error instanceof Error
          ? error.message
          : 'Camera permission was denied.',
      );

      return false;
    }
  }, [loadDevices]);

  const startCamera = useCallback(
    async (deviceId?: string) => {
      if (!isCameraSupported()) {
        setPermissionStatus('unsupported');
        setErrorMessage('Camera API is not supported in this environment.');
        return null;
      }

      const targetDeviceId = deviceId || selectedDeviceId;

      setIsStartingCamera(true);
      setErrorMessage('');

      try {
        stopCamera();

        const nextStream = await navigator.mediaDevices.getUserMedia({
          video: targetDeviceId
            ? {
                deviceId: {
                  exact: targetDeviceId,
                },
                width: {
                  ideal: 1920,
                },
                height: {
                  ideal: 1080,
                },
              }
            : {
                width: {
                  ideal: 1920,
                },
                height: {
                  ideal: 1080,
                },
              },
          audio: false,
        });

        streamRef.current = nextStream;
        setStream(nextStream);
        setPermissionStatus('granted');

        const refreshedDevices = await loadDevices();

        if (!targetDeviceId && refreshedDevices[0]?.deviceId) {
          setSelectedDeviceId(refreshedDevices[0].deviceId);
        }

        return nextStream;
      } catch (error) {
        setPermissionStatus('error');
        setErrorMessage(
          error instanceof Error ? error.message : 'Failed to start camera.',
        );
        return null;
      } finally {
        setIsStartingCamera(false);
      }
    },
    [loadDevices, selectedDeviceId, stopCamera],
  );

  const selectDevice = useCallback(
    async (deviceId: string) => {
      setSelectedDeviceId(deviceId);

      if (streamRef.current) {
        await startCamera(deviceId);
      }
    },
    [startCamera],
  );

  useEffect(() => {
    void loadDevices();

    const handleDeviceChange = () => {
      void loadDevices();
    };

    if (isCameraSupported()) {
      navigator.mediaDevices.addEventListener('devicechange', handleDeviceChange);
    }

    return () => {
      if (isCameraSupported()) {
        navigator.mediaDevices.removeEventListener(
          'devicechange',
          handleDeviceChange,
        );
      }

      stopCamera();
    };
  }, [loadDevices, stopCamera]);

  const state = useMemo(
    () => ({
      permissionStatus,
      devices,
      selectedDeviceId,
      stream,
      errorMessage,
      isLoadingDevices,
      isStartingCamera,
    }),
    [
      permissionStatus,
      devices,
      selectedDeviceId,
      stream,
      errorMessage,
      isLoadingDevices,
      isStartingCamera,
    ],
  );

  return {
    ...state,
    loadDevices,
    requestPermission,
    startCamera,
    stopCamera,
    selectDevice,
  };
}
TS

cat > apps/booth-ui/src/components/camera/CameraDeviceSelector.tsx <<'TSX'
import React from 'react';
import type { CameraDevice } from '../../camera';

type CameraDeviceSelectorProps = {
  devices: CameraDevice[];
  selectedDeviceId: string;
  isLoading?: boolean;
  disabled?: boolean;
  onSelectDevice: (deviceId: string) => void;
  onRefreshDevices: () => void;
};

export function CameraDeviceSelector({
  devices,
  selectedDeviceId,
  isLoading = false,
  disabled = false,
  onSelectDevice,
  onRefreshDevices,
}: CameraDeviceSelectorProps) {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-4 shadow-sm">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Camera Device
          </p>
          <p className="mt-1 text-sm font-bold text-slate-700">
            Pilih kamera yang dipakai booth.
          </p>
        </div>

        <button
          type="button"
          onClick={onRefreshDevices}
          disabled={disabled || isLoading}
          className="rounded-2xl border border-slate-200 px-4 py-2 text-xs font-black text-slate-700 disabled:opacity-50"
        >
          {isLoading ? 'Loading...' : 'Refresh'}
        </button>
      </div>

      <label className="mt-4 block">
        <span className="text-xs font-black uppercase tracking-wider text-slate-400">
          Active Camera
        </span>

        <select
          value={selectedDeviceId}
          onChange={(event) => onSelectDevice(event.target.value)}
          disabled={disabled || isLoading || devices.length === 0}
          className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-bold text-slate-800 outline-none disabled:opacity-50"
        >
          {devices.length === 0 ? (
            <option value="">No camera detected</option>
          ) : (
            devices.map((device) => (
              <option key={device.deviceId} value={device.deviceId}>
                {device.label}
              </option>
            ))
          )}
        </select>
      </label>
    </div>
  );
}
TSX

cat > apps/booth-ui/src/components/camera/CameraLivePreview.tsx <<'TSX'
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
TSX

cat > apps/booth-ui/src/components/camera/CameraSetupPanel.tsx <<'TSX'
import React from 'react';
import { useCameraDevices } from '../../camera';
import { CameraDeviceSelector } from './CameraDeviceSelector';
import { CameraLivePreview } from './CameraLivePreview';

export function CameraSetupPanel() {
  const {
    permissionStatus,
    devices,
    selectedDeviceId,
    stream,
    errorMessage,
    isLoadingDevices,
    isStartingCamera,
    loadDevices,
    requestPermission,
    startCamera,
    stopCamera,
    selectDevice,
  } = useCameraDevices();

  const hasActiveStream = Boolean(stream);

  const handleStartCamera = async () => {
    if (permissionStatus !== 'granted') {
      const granted = await requestPermission();

      if (!granted) {
        return;
      }
    }

    await startCamera();
  };

  return (
    <section className="rounded-[2rem] border border-slate-200 bg-slate-50 p-5">
      <div className="mb-5 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-black uppercase tracking-[0.2em] text-slate-400">
            Camera Setup
          </p>
          <h3 className="mt-1 text-2xl font-black text-slate-950">
            Live Camera Preview
          </h3>
          <p className="mt-1 text-sm font-semibold text-slate-500">
            Pilih kamera, request permission, lalu cek live preview.
          </p>
        </div>

        <span className="rounded-full bg-white px-3 py-1 text-xs font-black uppercase tracking-wider text-slate-600">
          {permissionStatus}
        </span>
      </div>

      <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_340px]">
        <CameraLivePreview
          stream={stream}
          isStarting={isStartingCamera}
          errorMessage={errorMessage}
        />

        <div className="space-y-4">
          <CameraDeviceSelector
            devices={devices}
            selectedDeviceId={selectedDeviceId}
            isLoading={isLoadingDevices}
            disabled={isStartingCamera}
            onSelectDevice={(deviceId) => void selectDevice(deviceId)}
            onRefreshDevices={() => void loadDevices()}
          />

          <div className="grid gap-3">
            <button
              type="button"
              onClick={handleStartCamera}
              disabled={isStartingCamera}
              className="rounded-2xl bg-slate-950 px-5 py-4 text-sm font-black text-white disabled:opacity-50"
            >
              {isStartingCamera
                ? 'Starting Camera...'
                : hasActiveStream
                  ? 'Restart Camera'
                  : 'Start Camera'}
            </button>

            <button
              type="button"
              onClick={stopCamera}
              disabled={!hasActiveStream}
              className="rounded-2xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-black text-red-700 disabled:opacity-50"
            >
              Stop Camera
            </button>

            {devices.length === 0 && (
              <p className="rounded-2xl bg-yellow-50 px-4 py-3 text-xs font-bold text-yellow-800">
                Kalau kamera tidak muncul, klik Start Camera dulu supaya browser/Electron
                minta permission kamera.
              </p>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
TSX

cat > apps/booth-ui/src/camera/index.ts <<'TS'
export * from './types';
export * from './useCameraDevices';
TS

cat > apps/booth-ui/src/components/camera/index.ts <<'TS'
export * from './CameraDeviceSelector';
export * from './CameraLivePreview';
export * from './CameraSetupPanel';
TS

echo ""
echo "Created:"
echo "- apps/booth-ui/src/camera/types.ts"
echo "- apps/booth-ui/src/camera/useCameraDevices.ts"
echo "- apps/booth-ui/src/camera/index.ts"
echo "- apps/booth-ui/src/components/camera/CameraDeviceSelector.tsx"
echo "- apps/booth-ui/src/components/camera/CameraLivePreview.tsx"
echo "- apps/booth-ui/src/components/camera/CameraSetupPanel.tsx"
echo "- apps/booth-ui/src/components/camera/index.ts"
echo ""
echo "Phase 9A1 completed."
