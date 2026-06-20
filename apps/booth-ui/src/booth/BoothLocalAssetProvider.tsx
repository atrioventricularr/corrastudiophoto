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
  clearBoothLocalAssets,
  deleteBoothLocalAsset,
  deleteBoothLocalAssetsBySession,
  getBoothLocalAssetsBySession,
  listBoothLocalAssets,
  saveBoothLocalAsset,
  summarizeBoothLocalAssets,
} from './booth-local-assets-db';
import type {
  BoothLocalAssetRecord,
  SaveBoothLocalAssetInput,
} from './booth-local-asset-types';

type BoothLocalAssetContextValue = {
  assets: BoothLocalAssetRecord[];
  isLoading: boolean;
  error: string;
  summary: ReturnType<typeof summarizeBoothLocalAssets>;
  refreshAssets: () => Promise<void>;
  saveAsset: (input: SaveBoothLocalAssetInput) => Promise<BoothLocalAssetRecord | null>;
  deleteAsset: (assetId: string) => Promise<void>;
  clearSessionAssets: (sessionId: string) => Promise<void>;
  clearAllAssets: () => Promise<void>;
  getSessionAssets: (sessionId: string) => Promise<BoothLocalAssetRecord[]>;
};

const BoothLocalAssetContext =
  createContext<BoothLocalAssetContextValue | null>(null);

type BoothLocalAssetProviderProps = {
  children: ReactNode;
};

export function BoothLocalAssetProvider({
  children,
}: BoothLocalAssetProviderProps) {
  const [assets, setAssets] = useState<BoothLocalAssetRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');

  const refreshAssets = useCallback(async () => {
    setIsLoading(true);
    setError('');

    try {
      const nextAssets = await listBoothLocalAssets();
      setAssets(nextAssets);
    } catch (caughtError) {
      const message =
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to load local booth assets.';

      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshAssets();
  }, [refreshAssets]);

  const saveAsset = useCallback(
    async (input: SaveBoothLocalAssetInput) => {
      setError('');

      try {
        const asset = await saveBoothLocalAsset(input);
        await refreshAssets();
        return asset;
      } catch (caughtError) {
        const message =
          caughtError instanceof Error
            ? caughtError.message
            : 'Failed to save local booth asset.';

        setError(message);
        return null;
      }
    },
    [refreshAssets],
  );

  const deleteAsset = useCallback(
    async (assetId: string) => {
      setError('');

      try {
        await deleteBoothLocalAsset(assetId);
        await refreshAssets();
      } catch (caughtError) {
        const message =
          caughtError instanceof Error
            ? caughtError.message
            : 'Failed to delete local booth asset.';

        setError(message);
      }
    },
    [refreshAssets],
  );

  const clearSessionAssets = useCallback(
    async (sessionId: string) => {
      setError('');

      try {
        await deleteBoothLocalAssetsBySession(sessionId);
        await refreshAssets();
      } catch (caughtError) {
        const message =
          caughtError instanceof Error
            ? caughtError.message
            : 'Failed to clear local session assets.';

        setError(message);
      }
    },
    [refreshAssets],
  );

  const clearAllAssets = useCallback(async () => {
    setError('');

    try {
      await clearBoothLocalAssets();
      await refreshAssets();
    } catch (caughtError) {
      const message =
        caughtError instanceof Error
          ? caughtError.message
          : 'Failed to clear all local booth assets.';

      setError(message);
    }
  }, [refreshAssets]);

  const getSessionAssets = useCallback(async (sessionId: string) => {
    return getBoothLocalAssetsBySession(sessionId);
  }, []);

  const summary = useMemo(() => {
    return summarizeBoothLocalAssets(assets);
  }, [assets]);

  const value = useMemo<BoothLocalAssetContextValue>(() => {
    return {
      assets,
      isLoading,
      error,
      summary,
      refreshAssets,
      saveAsset,
      deleteAsset,
      clearSessionAssets,
      clearAllAssets,
      getSessionAssets,
    };
  }, [
    assets,
    isLoading,
    error,
    summary,
    refreshAssets,
    saveAsset,
    deleteAsset,
    clearSessionAssets,
    clearAllAssets,
    getSessionAssets,
  ]);

  return (
    <BoothLocalAssetContext.Provider value={value}>
      {children}
    </BoothLocalAssetContext.Provider>
  );
}

export function useBoothLocalAssets() {
  const context = useContext(BoothLocalAssetContext);

  if (!context) {
    throw new Error(
      'useBoothLocalAssets must be used inside BoothLocalAssetProvider',
    );
  }

  return context;
}
