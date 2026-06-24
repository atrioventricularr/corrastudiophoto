const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('corraHardware', {
  getRuntimeInfo: () => ipcRenderer.invoke('corra:hardware-runtime-info'),
  listPrinters: () => ipcRenderer.invoke('corra:hardware-list-printers'),
  printCurrentPage: (payload) => ipcRenderer.invoke('corra:hardware-print-current-page', payload || {}),
  openUserData: () => ipcRenderer.invoke('corra:hardware-open-user-data'),
  setFullscreen: (enabled) =>
    ipcRenderer.invoke('corra:kiosk-set-fullscreen', { enabled: Boolean(enabled) }),
  setKiosk: (enabled) =>
    ipcRenderer.invoke('corra:kiosk-set-kiosk', { enabled: Boolean(enabled) }),
});
