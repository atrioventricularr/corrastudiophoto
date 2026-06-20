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
import { BoothLocalAssetAutoSaver } from './BoothLocalAssetAutoSaver';
import { BoothLocalAssetProvider } from './BoothLocalAssetProvider';

type BoothRuntimeProvidersProps = {
  children: ReactNode;
};

export function BoothRuntimeProviders({
  children,
}: BoothRuntimeProvidersProps) {
  return (
    <BoothFlowProvider>
      <BoothLifecycleLoggerProvider>
        <BoothLocalAssetProvider>
          <CameraCaptureGuideProvider>
            <CapturedFramesProvider>
              <CameraRenderOutputProvider>
                <CameraPrintQueueProvider>
                  <BoothLifecycleAutoTracker />
                  <BoothLocalAssetAutoSaver />
                  {children}
                </CameraPrintQueueProvider>
              </CameraRenderOutputProvider>
            </CapturedFramesProvider>
          </CameraCaptureGuideProvider>
        </BoothLocalAssetProvider>
      </BoothLifecycleLoggerProvider>
    </BoothFlowProvider>
  );
}
