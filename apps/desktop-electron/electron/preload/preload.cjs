const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("corraDesktop", {
  device: {
    getInfo: () => ipcRenderer.invoke("corra:device-info"),
  },
  license: {
    verify: (input) => ipcRenderer.invoke("corra:license-verify", input),
    readCache: () => ipcRenderer.invoke("corra:license-read-cache"),
    clearCache: () => ipcRenderer.invoke("corra:license-clear-cache"),
  },
  assets: {
    pickBackground: () => ipcRenderer.invoke("corra:asset-pick-background"),
    pickQris: () => ipcRenderer.invoke("corra:asset-pick-qris"),
  },
  secureVault: {
    setSecret: (input) => ipcRenderer.invoke("corra:vault-set-secret", input),
    getSecretStatus: (input) => ipcRenderer.invoke("corra:vault-get-secret-status", input),
    deleteSecret: (input) => ipcRenderer.invoke("corra:vault-delete-secret", input),
    listSecretStatuses: () => ipcRenderer.invoke("corra:vault-list-secret-statuses"),
  },
});

// Corra Booth print bridge
;(() => {
  try {
    const electronRuntime = require('electron');

    electronRuntime.contextBridge.exposeInMainWorld('corraPrintBridge', {
      printImageDataUrl: (input) =>
        electronRuntime.ipcRenderer.invoke('corra:print-image-data-url', input),
    });
  } catch (error) {
    console.error('[corra] failed to expose print bridge', error);
  }
})();
