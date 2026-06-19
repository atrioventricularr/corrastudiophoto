#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " Phase 10D1B - Layout Provider Local Storage"
echo "========================================"

mkdir -p apps/booth-ui/src/layouts

cat > apps/booth-ui/src/layouts/local-layout-storage.ts <<'TS'
import {
  defaultActivePhotoLayout,
  defaultLayoutGuideSettings,
  defaultPhotoLayouts,
} from './default-layouts';
import type {
  LayoutGuideSettings,
  PhotoLayout,
} from './types';

const LAYOUTS_KEY = 'corra.photoLayouts.v1';
const ACTIVE_LAYOUT_ID_KEY = 'corra.activePhotoLayoutId.v1';
const GUIDE_SETTINGS_KEY = 'corra.layoutGuideSettings.v1';

export function loadPhotoLayouts(): PhotoLayout[] {
  if (typeof window === 'undefined') return defaultPhotoLayouts;

  try {
    const raw = window.localStorage.getItem(LAYOUTS_KEY);
    const parsed = raw ? JSON.parse(raw) : null;

    if (!Array.isArray(parsed) || parsed.length === 0) {
      return defaultPhotoLayouts;
    }

    return parsed as PhotoLayout[];
  } catch {
    return defaultPhotoLayouts;
  }
}

export function savePhotoLayouts(layouts: PhotoLayout[]): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(LAYOUTS_KEY, JSON.stringify(layouts));
}

export function loadActivePhotoLayoutId(): string {
  if (typeof window === 'undefined') return defaultActivePhotoLayout.id;

  return (
    window.localStorage.getItem(ACTIVE_LAYOUT_ID_KEY) ||
    defaultActivePhotoLayout.id
  );
}

export function saveActivePhotoLayoutId(layoutId: string): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(ACTIVE_LAYOUT_ID_KEY, layoutId);
}

export function loadLayoutGuideSettings(): LayoutGuideSettings {
  if (typeof window === 'undefined') return defaultLayoutGuideSettings;

  try {
    const raw = window.localStorage.getItem(GUIDE_SETTINGS_KEY);
    const parsed = raw ? JSON.parse(raw) : null;

    return {
      ...defaultLayoutGuideSettings,
      ...(parsed || {}),
    };
  } catch {
    return defaultLayoutGuideSettings;
  }
}

export function saveLayoutGuideSettings(settings: LayoutGuideSettings): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(GUIDE_SETTINGS_KEY, JSON.stringify(settings));
}

export function clearLayoutStorage(): void {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(LAYOUTS_KEY);
  window.localStorage.removeItem(ACTIVE_LAYOUT_ID_KEY);
  window.localStorage.removeItem(GUIDE_SETTINGS_KEY);
}
TS

cat > apps/booth-ui/src/layouts/LayoutProvider.tsx <<'TSX'
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
TSX

grep -q "local-layout-storage" apps/booth-ui/src/layouts/index.ts || cat >> apps/booth-ui/src/layouts/index.ts <<'TS'
export * from './local-layout-storage';
export * from './LayoutProvider';
TS

python - <<'PY'
from pathlib import Path

path = Path("apps/booth-ui/src/main.tsx")
text = path.read_text()

if "LayoutProvider" not in text:
    lines = text.splitlines()
    insert_at = 0

    for index, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = index + 1

    lines.insert(insert_at, "import { LayoutProvider } from './layouts';")
    text = "\n".join(lines) + "\n"

if "<LayoutProvider>" not in text:
    text = text.replace(
        """<PrinterProfileProvider>
              <ThemedBackground />
              <App />
            </PrinterProfileProvider>""",
        """<PrinterProfileProvider>
              <LayoutProvider>
                <ThemedBackground />
                <App />
              </LayoutProvider>
            </PrinterProfileProvider>""",
    )

path.write_text(text)
print("PATCH file:", path)
PY

echo ""
echo "Created:"
echo "- apps/booth-ui/src/layouts/local-layout-storage.ts"
echo "- apps/booth-ui/src/layouts/LayoutProvider.tsx"
echo ""
echo "Patched:"
echo "- apps/booth-ui/src/layouts/index.ts"
echo "- apps/booth-ui/src/main.tsx"
echo ""
echo "Phase 10D1B completed."
