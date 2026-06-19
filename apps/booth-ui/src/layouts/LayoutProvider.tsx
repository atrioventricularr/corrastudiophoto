import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  defaultActivePhotoLayout,
  defaultLayoutGuideSettings,
  defaultPhotoLayouts,
} from './default-layouts';
import {
  clearLayoutStorage,
  loadActivePhotoLayoutId,
  loadLayoutGuideSettings,
  loadPhotoLayouts,
  saveActivePhotoLayoutId,
  saveLayoutGuideSettings,
  savePhotoLayouts,
} from './local-layout-storage';
import type {
  LayoutGuideSettings,
  PhotoLayout,
  PhotoLayoutSlot,
} from './types';

type LayoutContextValue = {
  layouts: PhotoLayout[];
  activeLayoutId: string;
  activeLayout: PhotoLayout;
  guideSettings: LayoutGuideSettings;

  setActiveLayoutId: (layoutId: string) => void;
  addLayout: (layout: PhotoLayout) => void;
  updateLayout: (layoutId: string, patch: Partial<PhotoLayout>) => void;
  removeLayout: (layoutId: string) => void;

  addSlot: (layoutId: string, slot: PhotoLayoutSlot) => void;
  updateSlot: (
    layoutId: string,
    slotId: string,
    patch: Partial<PhotoLayoutSlot>,
  ) => void;
  removeSlot: (layoutId: string, slotId: string) => void;

  updateGuideSettings: (patch: Partial<LayoutGuideSettings>) => void;
  resetLayouts: () => void;
};

const LayoutContext = createContext<LayoutContextValue | null>(null);

type LayoutProviderProps = {
  children: ReactNode;
};

function sortSlots(slots: PhotoLayoutSlot[]): PhotoLayoutSlot[] {
  return [...slots].sort((a, b) => a.captureOrder - b.captureOrder);
}

export function LayoutProvider({ children }: LayoutProviderProps) {
  const [layouts, setLayouts] = useState<PhotoLayout[]>(() =>
    loadPhotoLayouts(),
  );
  const [activeLayoutId, setActiveLayoutIdState] = useState<string>(() =>
    loadActivePhotoLayoutId(),
  );
  const [guideSettings, setGuideSettings] = useState<LayoutGuideSettings>(() =>
    loadLayoutGuideSettings(),
  );

  useEffect(() => {
    savePhotoLayouts(layouts);
  }, [layouts]);

  useEffect(() => {
    saveActivePhotoLayoutId(activeLayoutId);
  }, [activeLayoutId]);

  useEffect(() => {
    saveLayoutGuideSettings(guideSettings);
  }, [guideSettings]);

  const activeLayout = useMemo(() => {
    return (
      layouts.find((layout) => layout.id === activeLayoutId) ||
      layouts[0] ||
      defaultActivePhotoLayout
    );
  }, [activeLayoutId, layouts]);

  const setActiveLayoutId = useCallback((layoutId: string) => {
    setActiveLayoutIdState(layoutId);
  }, []);

  const addLayout = useCallback((layout: PhotoLayout) => {
    setLayouts((current) => {
      const withoutDuplicate = current.filter((item) => item.id !== layout.id);
      return [...withoutDuplicate, layout];
    });
    setActiveLayoutIdState(layout.id);
  }, []);

  const updateLayout = useCallback(
    (layoutId: string, patch: Partial<PhotoLayout>) => {
      setLayouts((current) =>
        current.map((layout) =>
          layout.id === layoutId
            ? {
                ...layout,
                ...patch,
                updatedAt: new Date().toISOString(),
              }
            : layout,
        ),
      );
    },
    [],
  );

  const removeLayout = useCallback(
    (layoutId: string) => {
      setLayouts((current) => {
        const next = current.filter((layout) => layout.id !== layoutId);

        if (activeLayoutId === layoutId) {
          setActiveLayoutIdState(next[0]?.id || defaultActivePhotoLayout.id);
        }

        return next.length > 0 ? next : defaultPhotoLayouts;
      });
    },
    [activeLayoutId],
  );

  const addSlot = useCallback((layoutId: string, slot: PhotoLayoutSlot) => {
    setLayouts((current) =>
      current.map((layout) =>
        layout.id === layoutId
          ? {
              ...layout,
              slots: sortSlots([...layout.slots, slot]),
              updatedAt: new Date().toISOString(),
            }
          : layout,
      ),
    );
  }, []);

  const updateSlot = useCallback(
    (layoutId: string, slotId: string, patch: Partial<PhotoLayoutSlot>) => {
      setLayouts((current) =>
        current.map((layout) =>
          layout.id === layoutId
            ? {
                ...layout,
                slots: sortSlots(
                  layout.slots.map((slot) =>
                    slot.id === slotId
                      ? {
                          ...slot,
                          ...patch,
                        }
                      : slot,
                  ),
                ),
                updatedAt: new Date().toISOString(),
              }
            : layout,
        ),
      );
    },
    [],
  );

  const removeSlot = useCallback((layoutId: string, slotId: string) => {
    setLayouts((current) =>
      current.map((layout) =>
        layout.id === layoutId
          ? {
              ...layout,
              slots: layout.slots.filter((slot) => slot.id !== slotId),
              updatedAt: new Date().toISOString(),
            }
          : layout,
      ),
    );
  }, []);

  const updateGuideSettings = useCallback(
    (patch: Partial<LayoutGuideSettings>) => {
      setGuideSettings((current) => ({
        ...current,
        ...patch,
      }));
    },
    [],
  );

  const resetLayouts = useCallback(() => {
    clearLayoutStorage();
    setLayouts(defaultPhotoLayouts);
    setActiveLayoutIdState(defaultActivePhotoLayout.id);
    setGuideSettings(defaultLayoutGuideSettings);
  }, []);

  const value = useMemo<LayoutContextValue>(() => {
    return {
      layouts,
      activeLayoutId,
      activeLayout,
      guideSettings,

      setActiveLayoutId,
      addLayout,
      updateLayout,
      removeLayout,

      addSlot,
      updateSlot,
      removeSlot,

      updateGuideSettings,
      resetLayouts,
    };
  }, [
    layouts,
    activeLayoutId,
    activeLayout,
    guideSettings,
    setActiveLayoutId,
    addLayout,
    updateLayout,
    removeLayout,
    addSlot,
    updateSlot,
    removeSlot,
    updateGuideSettings,
    resetLayouts,
  ]);

  return (
    <LayoutContext.Provider value={value}>{children}</LayoutContext.Provider>
  );
}

export function useLayouts(): LayoutContextValue {
  const context = useContext(LayoutContext);

  if (!context) {
    throw new Error('useLayouts must be used inside LayoutProvider');
  }

  return context;
}
