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
