import React, { type ReactNode } from 'react';
import {
  CameraCaptureGuideProvider,
  CameraPrintQueueProvider,
  CameraRenderOutputProvider,
  CapturedFramesProvider,
} from '../camera';
import { BoothFlowProvider } from './BoothFlowProvider';
import { BoothLifecycleAutoTracker } from './BoothLifecycleAutoTracker';
import { BoothLifecycleLoggerProvider } from './BoothLifecycleLoggerProvider';

type BoothRuntimeProvidersProps = {
  children: ReactNode;
};

export function BoothRuntimeProviders({
  children,
}: BoothRuntimeProvidersProps) {
  return (
    <BoothFlowProvider>
      <BoothLifecycleLoggerProvider>
        <CameraCaptureGuideProvider>
          <CapturedFramesProvider>
            <CameraRenderOutputProvider>
              <CameraPrintQueueProvider>
                <BoothLifecycleAutoTracker />
                {children}
              </CameraPrintQueueProvider>
            </CameraRenderOutputProvider>
          </CapturedFramesProvider>
        </CameraCaptureGuideProvider>
      </BoothLifecycleLoggerProvider>
    </BoothFlowProvider>
  );
}
