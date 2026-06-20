import React, { type ReactNode } from 'react';
import {
  CameraCaptureGuideProvider,
  CameraPrintQueueProvider,
  CameraRenderOutputProvider,
  CapturedFramesProvider,
} from '../camera';
import { BoothFlowProvider } from './BoothFlowProvider';

type BoothRuntimeProvidersProps = {
  children: ReactNode;
};

export function BoothRuntimeProviders({
  children,
}: BoothRuntimeProvidersProps) {
  return (
    <BoothFlowProvider>
      <CameraCaptureGuideProvider>
        <CapturedFramesProvider>
          <CameraRenderOutputProvider>
            <CameraPrintQueueProvider>
              {children}
            </CameraPrintQueueProvider>
          </CameraRenderOutputProvider>
        </CapturedFramesProvider>
      </CameraCaptureGuideProvider>
    </BoothFlowProvider>
  );
}
