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
