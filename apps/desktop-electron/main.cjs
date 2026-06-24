const path = require('node:path');
const fs = require('node:fs');
const { app, BrowserWindow } = require('electron');

try { require('./corra-disk-persistence.cjs'); } catch (error) {
  console.warn('[Corra] disk IPC not loaded:', error.message);
}

try { require('./corra-hardware-diagnostics.cjs'); } catch (error) {
  console.warn('[Corra] hardware IPC not loaded:', error.message);
}

function findBoothDistIndex() {
  const candidates = [
    path.join(__dirname, '..', 'booth-ui', 'dist', 'index.html'),
    path.join(__dirname, '..', '..', 'apps', 'booth-ui', 'dist', 'index.html'),
    path.join(__dirname, '..', '..', 'bundle', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, '..', 'booth-ui-dist', 'index.html'),
    path.join(__dirname, 'booth-ui-dist', 'index.html'),
  ];

  return candidates.find((candidate) => fs.existsSync(candidate));
}

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 960,
    backgroundColor: '#020617',
    fullscreen: process.env.CORRA_KIOSK === '1',
    kiosk: process.env.CORRA_KIOSK === '1',
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  const devUrl = process.env.CORRA_DEV_URL || 'http://127.0.0.1:5173';
  const distIndex = findBoothDistIndex();

  if (process.env.CORRA_DEV === '1') {
    win.loadURL(`${devUrl}/?mode=booth&dev=1`);
  } else if (distIndex) {
    win.loadFile(distIndex, {
      query: {
        mode: 'booth',
        dev: process.env.CORRA_DEV === '1' ? '1' : '0',
        kiosk: process.env.CORRA_KIOSK === '1' ? '1' : '0',
      },
    });
  } else {
    win.loadURL(`${devUrl}/?mode=booth&dev=1`);
  }

  if (process.env.CORRA_DEVTOOLS === '1') {
    win.webContents.openDevTools({ mode: 'detach' });
  }

  return win;
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
