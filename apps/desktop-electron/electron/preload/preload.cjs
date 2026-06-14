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
});
