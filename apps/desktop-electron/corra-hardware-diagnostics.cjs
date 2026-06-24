const { app, BrowserWindow, ipcMain, shell } = require('electron');
const os = require('node:os');

function getActiveWindow() {
  return BrowserWindow.getFocusedWindow() || BrowserWindow.getAllWindows()[0] || null;
}

function safeHandle(channel, handler) {
  try {
    ipcMain.removeHandler(channel);
  } catch (_) {}

  ipcMain.handle(channel, handler);
}

safeHandle('corra:hardware-runtime-info', async () => {
  return {
    ok: true,
    appVersion: app?.getVersion ? app.getVersion() : 'unknown',
    platform: process.platform,
    arch: process.arch,
    node: process.versions.node,
    electron: process.versions.electron,
    chrome: process.versions.chrome,
    hostname: os.hostname(),
    username: os.userInfo().username,
    userDataPath: app.getPath('userData'),
    tempPath: app.getPath('temp'),
    timestamp: new Date().toISOString(),
  };
});

safeHandle('corra:hardware-list-printers', async () => {
  const win = getActiveWindow();

  if (!win) {
    return { ok: false, error: 'No active BrowserWindow.', printers: [] };
  }

  try {
    const printers =
      typeof win.webContents.getPrintersAsync === 'function'
        ? await win.webContents.getPrintersAsync()
        : win.webContents.getPrinters();

    return {
      ok: true,
      printers: printers.map((printer) => ({
        name: printer.name,
        displayName: printer.displayName || printer.name,
        description: printer.description || '',
        status: printer.status || 0,
        isDefault: Boolean(printer.isDefault),
        options: printer.options || {},
      })),
    };
  } catch (error) {
    return {
      ok: false,
      error: error && error.message ? error.message : 'Failed to list printers.',
      printers: [],
    };
  }
});

safeHandle('corra:hardware-print-current-page', async (_event, payload) => {
  const win = getActiveWindow();

  if (!win) {
    return { ok: false, error: 'No active BrowserWindow.' };
  }

  const options = {
    silent: Boolean(payload && payload.silent),
    printBackground: true,
    deviceName: payload && payload.printerName ? String(payload.printerName) : undefined,
    copies: payload && payload.copies ? Number(payload.copies) : 1,
    pageSize: payload && payload.pageSize ? payload.pageSize : undefined,
  };

  return await new Promise((resolve) => {
    try {
      win.webContents.print(options, (success, failureReason) => {
        if (success) {
          resolve({ ok: true });
        } else {
          resolve({
            ok: false,
            error: failureReason || 'Print failed or cancelled.',
          });
        }
      });
    } catch (error) {
      resolve({
        ok: false,
        error: error && error.message ? error.message : 'Print failed.',
      });
    }
  });
});

safeHandle('corra:hardware-open-user-data', async () => {
  try {
    const result = await shell.openPath(app.getPath('userData'));
    if (result) return { ok: false, error: result };
    return { ok: true };
  } catch (error) {
    return {
      ok: false,
      error: error && error.message ? error.message : 'Failed to open userData.',
    };
  }
});

safeHandle('corra:kiosk-set-fullscreen', async (_event, payload) => {
  const win = getActiveWindow();
  if (!win) return { ok: false, error: 'No active BrowserWindow.' };

  win.setFullScreen(Boolean(payload && payload.enabled));

  return {
    ok: true,
    isFullScreen: win.isFullScreen(),
    isKiosk: win.isKiosk(),
  };
});

safeHandle('corra:kiosk-set-kiosk', async (_event, payload) => {
  const win = getActiveWindow();
  if (!win) return { ok: false, error: 'No active BrowserWindow.' };

  win.setKiosk(Boolean(payload && payload.enabled));

  return {
    ok: true,
    isFullScreen: win.isFullScreen(),
    isKiosk: win.isKiosk(),
  };
});

console.log('[Corra] hardware diagnostics IPC registered.');
