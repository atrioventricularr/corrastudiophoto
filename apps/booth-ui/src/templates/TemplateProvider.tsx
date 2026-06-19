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
  defaultActivePhotoTemplate,
  defaultPhotoTemplates,
} from './default-templates';
import {
  clearTemplateStorage,
  loadActivePhotoTemplateId,
  loadPhotoTemplates,
  saveActivePhotoTemplateId,
  savePhotoTemplates,
} from './local-template-storage';
import type {
  PhotoTemplate,
  PhotoTemplateLayer,
  PhotoTemplateStatus,
  TemplateAssetRef,
} from './types';

type TemplateContextValue = {
  templates: PhotoTemplate[];
  activeTemplateId: string;
  activeTemplate: PhotoTemplate;

  setActiveTemplateId: (templateId: string) => void;
  addTemplate: (template: PhotoTemplate) => void;
  updateTemplate: (templateId: string, patch: Partial<PhotoTemplate>) => void;
  removeTemplate: (templateId: string) => void;

  setTemplateStatus: (
    templateId: string,
    status: PhotoTemplateStatus,
  ) => void;

  addTemplateAsset: (
    templateId: string,
    asset: TemplateAssetRef,
  ) => void;
  removeTemplateAsset: (
    templateId: string,
    assetId: string,
  ) => void;

  addTemplateLayer: (
    templateId: string,
    layer: PhotoTemplateLayer,
  ) => void;
  updateTemplateLayer: (
    templateId: string,
    layerId: string,
    patch: Partial<PhotoTemplateLayer>,
  ) => void;
  removeTemplateLayer: (
    templateId: string,
    layerId: string,
  ) => void;

  resetTemplates: () => void;
};

const TemplateContext = createContext<TemplateContextValue | null>(null);

type TemplateProviderProps = {
  children: ReactNode;
};

function sortLayers(layers: PhotoTemplateLayer[]): PhotoTemplateLayer[] {
  return [...layers].sort((a, b) => a.zIndex - b.zIndex);
}

export function TemplateProvider({ children }: TemplateProviderProps) {
  const [templates, setTemplates] = useState<PhotoTemplate[]>(() =>
    loadPhotoTemplates(),
  );
  const [activeTemplateId, setActiveTemplateIdState] = useState<string>(() =>
    loadActivePhotoTemplateId(),
  );

  useEffect(() => {
    savePhotoTemplates(templates);
  }, [templates]);

  useEffect(() => {
    saveActivePhotoTemplateId(activeTemplateId);
  }, [activeTemplateId]);

  const activeTemplate = useMemo(() => {
    return (
      templates.find((template) => template.id === activeTemplateId) ||
      templates[0] ||
      defaultActivePhotoTemplate
    );
  }, [activeTemplateId, templates]);

  const setActiveTemplateId = useCallback((templateId: string) => {
    setActiveTemplateIdState(templateId);
  }, []);

  const addTemplate = useCallback((template: PhotoTemplate) => {
    setTemplates((current) => {
      const withoutDuplicate = current.filter(
        (item) => item.id !== template.id,
      );

      return [...withoutDuplicate, template];
    });
    setActiveTemplateIdState(template.id);
  }, []);

  const updateTemplate = useCallback(
    (templateId: string, patch: Partial<PhotoTemplate>) => {
      setTemplates((current) =>
        current.map((template) =>
          template.id === templateId
            ? {
                ...template,
                ...patch,
                updatedAt: new Date().toISOString(),
              }
            : template,
        ),
      );
    },
    [],
  );

  const removeTemplate = useCallback(
    (templateId: string) => {
      setTemplates((current) => {
        const next = current.filter(
          (template) => template.id !== templateId,
        );

        if (activeTemplateId === templateId) {
          setActiveTemplateIdState(
            next[0]?.id || defaultActivePhotoTemplate.id,
          );
        }

        return next.length > 0 ? next : defaultPhotoTemplates;
      });
    },
    [activeTemplateId],
  );

  const setTemplateStatus = useCallback(
    (templateId: string, status: PhotoTemplateStatus) => {
      updateTemplate(templateId, {
        status,
      });
    },
    [updateTemplate],
  );

  const addTemplateAsset = useCallback(
    (templateId: string, asset: TemplateAssetRef) => {
      setTemplates((current) =>
        current.map((template) =>
          template.id === templateId
            ? {
                ...template,
                assets: [
                  ...template.assets.filter((item) => item.id !== asset.id),
                  asset,
                ],
                updatedAt: new Date().toISOString(),
              }
            : template,
        ),
      );
    },
    [],
  );

  const removeTemplateAsset = useCallback(
    (templateId: string, assetId: string) => {
      setTemplates((current) =>
        current.map((template) =>
          template.id === templateId
            ? {
                ...template,
                assets: template.assets.filter(
                  (asset) => asset.id !== assetId,
                ),
                layers: template.layers.filter(
                  (layer) => layer.assetId !== assetId,
                ),
                frameOverlayAssetId:
                  template.frameOverlayAssetId === assetId
                    ? undefined
                    : template.frameOverlayAssetId,
                backgroundAssetId:
                  template.backgroundAssetId === assetId
                    ? undefined
                    : template.backgroundAssetId,
                previewAssetId:
                  template.previewAssetId === assetId
                    ? undefined
                    : template.previewAssetId,
                updatedAt: new Date().toISOString(),
              }
            : template,
        ),
      );
    },
    [],
  );

  const addTemplateLayer = useCallback(
    (templateId: string, layer: PhotoTemplateLayer) => {
      setTemplates((current) =>
        current.map((template) =>
          template.id === templateId
            ? {
                ...template,
                layers: sortLayers([
                  ...template.layers.filter((item) => item.id !== layer.id),
                  layer,
                ]),
                updatedAt: new Date().toISOString(),
              }
            : template,
        ),
      );
    },
    [],
  );

  const updateTemplateLayer = useCallback(
    (
      templateId: string,
      layerId: string,
      patch: Partial<PhotoTemplateLayer>,
    ) => {
      setTemplates((current) =>
        current.map((template) =>
          template.id === templateId
            ? {
                ...template,
                layers: sortLayers(
                  template.layers.map((layer) =>
                    layer.id === layerId
                      ? {
                          ...layer,
                          ...patch,
                        }
                      : layer,
                  ),
                ),
                updatedAt: new Date().toISOString(),
              }
            : template,
        ),
      );
    },
    [],
  );

  const removeTemplateLayer = useCallback(
    (templateId: string, layerId: string) => {
      setTemplates((current) =>
        current.map((template) =>
          template.id === templateId
            ? {
                ...template,
                layers: template.layers.filter(
                  (layer) => layer.id !== layerId,
                ),
                updatedAt: new Date().toISOString(),
              }
            : template,
        ),
      );
    },
    [],
  );

  const resetTemplates = useCallback(() => {
    clearTemplateStorage();
    setTemplates(defaultPhotoTemplates);
    setActiveTemplateIdState(defaultActivePhotoTemplate.id);
  }, []);

  const value = useMemo<TemplateContextValue>(() => {
    return {
      templates,
      activeTemplateId,
      activeTemplate,

      setActiveTemplateId,
      addTemplate,
      updateTemplate,
      removeTemplate,

      setTemplateStatus,

      addTemplateAsset,
      removeTemplateAsset,

      addTemplateLayer,
      updateTemplateLayer,
      removeTemplateLayer,

      resetTemplates,
    };
  }, [
    templates,
    activeTemplateId,
    activeTemplate,
    setActiveTemplateId,
    addTemplate,
    updateTemplate,
    removeTemplate,
    setTemplateStatus,
    addTemplateAsset,
    removeTemplateAsset,
    addTemplateLayer,
    updateTemplateLayer,
    removeTemplateLayer,
    resetTemplates,
  ]);

  return (
    <TemplateContext.Provider value={value}>
      {children}
    </TemplateContext.Provider>
  );
}

export function useTemplates(): TemplateContextValue {
  const context = useContext(TemplateContext);

  if (!context) {
    throw new Error('useTemplates must be used inside TemplateProvider');
  }

  return context;
}
