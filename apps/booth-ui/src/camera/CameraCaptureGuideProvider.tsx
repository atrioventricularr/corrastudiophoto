import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { useLayouts } from '../layouts';
import {
  getCaptureGuideStep,
  getCaptureOrderedSlots,
  type CaptureGuideStep,
} from './capture-guide';

type CameraCaptureGuideContextValue = {
  activeIndex: number;
  activeStep: CaptureGuideStep | null;
  total: number;
  setActiveIndex: (index: number) => void;
  previousStep: () => void;
  nextStep: () => void;
  resetStep: () => void;
};

const CameraCaptureGuideContext =
  createContext<CameraCaptureGuideContextValue | null>(null);

type CameraCaptureGuideProviderProps = {
  children: ReactNode;
};

export function CameraCaptureGuideProvider({
  children,
}: CameraCaptureGuideProviderProps) {
  const { activeLayout } = useLayouts();
  const [activeIndex, setActiveIndexState] = useState(0);

  const orderedSlots = useMemo(
    () => getCaptureOrderedSlots(activeLayout),
    [activeLayout],
  );

  const activeStep = getCaptureGuideStep({
    layout: activeLayout,
    index: activeIndex,
  });

  useEffect(() => {
    if (activeIndex > orderedSlots.length - 1) {
      setActiveIndexState(Math.max(0, orderedSlots.length - 1));
    }
  }, [activeIndex, orderedSlots.length]);

  const setActiveIndex = (index: number) => {
    setActiveIndexState(
      Math.max(0, Math.min(index, Math.max(0, orderedSlots.length - 1))),
    );
  };

  const previousStep = () => {
    setActiveIndex(activeIndex - 1);
  };

  const nextStep = () => {
    setActiveIndex(activeIndex + 1);
  };

  const resetStep = () => {
    setActiveIndex(0);
  };

  return (
    <CameraCaptureGuideContext.Provider
      value={{
        activeIndex,
        activeStep,
        total: orderedSlots.length,
        setActiveIndex,
        previousStep,
        nextStep,
        resetStep,
      }}
    >
      {children}
    </CameraCaptureGuideContext.Provider>
  );
}

export function useCameraCaptureGuide(): CameraCaptureGuideContextValue {
  const context = useContext(CameraCaptureGuideContext);

  if (!context) {
    throw new Error(
      'useCameraCaptureGuide must be used inside CameraCaptureGuideProvider',
    );
  }

  return context;
}

export function useOptionalCameraCaptureGuide():
  | CameraCaptureGuideContextValue
  | null {
  return useContext(CameraCaptureGuideContext);
}
