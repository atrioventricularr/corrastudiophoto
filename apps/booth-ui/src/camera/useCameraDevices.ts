import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { CameraDevice, CameraPermissionStatus } from './types';

function isCameraSupported(): boolean {
  if (typeof navigator === 'undefined') {
    return false;
  }

  const mediaDevices = navigator.mediaDevices;

  return Boolean(
    mediaDevices &&
      typeof mediaDevices.getUserMedia === 'function' &&
      typeof mediaDevices.enumerateDevices === 'function',
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
