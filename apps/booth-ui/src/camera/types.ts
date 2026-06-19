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
