function installCorraDiskBridge({ contextBridge, ipcRenderer }) {
  if (!contextBridge || !ipcRenderer) {
    console.warn('[corra-disk] Missing contextBridge/ipcRenderer.');
    return;
  }

  contextBridge.exposeInMainWorld('corraDisk', {
    getRoot: () => ipcRenderer.invoke('corra:disk-get-root'),
    openOutputFolder: (payload) => ipcRenderer.invoke('corra:disk-open-output-folder', payload),
    saveDataUrl: (payload) => ipcRenderer.invoke('corra:disk-save-data-url', payload),
    saveTextFile: (payload) => ipcRenderer.invoke('corra:disk-save-text-file', payload),
    listSessionFiles: (payload) => ipcRenderer.invoke('corra:disk-list-session-files', payload),
    deleteFile: (payload) => ipcRenderer.invoke('corra:disk-delete-file', payload),
    cleanupOlderThanDays: (payload) => ipcRenderer.invoke('corra:disk-cleanup-older-than-days', payload),
  });
}

module.exports = { installCorraDiskBridge };
