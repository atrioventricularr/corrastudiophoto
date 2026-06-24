# Phase 9E — Electron Disk Persistence Checklist

Status: code scaffold complete after TypeScript passes.

Completed:
- 9E1 Electron disk IPC module
- 9E2 Preload `window.corraDisk` bridge
- 9E3 Frontend disk persistence API
- 9E4 Local disk record registry
- 9E5 Dev/Admin disk persistence panel
- 9E6 Disk file browser and delete action
- 9E7 Disk retention cleanup
- 9E8 Delivery-step disk save panel and docs/checker

Output folder:

```txt
Electron app userData/corra-booth-output/<sessionId>/<kind>/...
```

Manual Electron patch fallback:

If the script cannot patch your Electron main/preload automatically, add these manually.

Main process:

```js
const { registerCorraDiskPersistence } = require('./corra-disk-persistence.cjs');
registerCorraDiskPersistence({ ipcMain, app, shell, dialog });
```

Preload:

```js
const { installCorraDiskBridge } = require('./corra-disk-preload.cjs');
installCorraDiskBridge({ contextBridge, ipcRenderer });
```
