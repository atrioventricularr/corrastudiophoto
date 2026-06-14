const { app, BrowserWindow, ipcMain, shell, dialog, protocol, net } = require("electron");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { pathToFileURL } = require("node:url");

const DEFAULT_VERIFY_LICENSE_URL =
  "https://uitnzrstkjvwiojbnpwg.supabase.co/functions/v1/verify-license";

let mainWindow = null;

protocol.registerSchemesAsPrivileged([
  {
    scheme: "corra-asset",
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true,
      corsEnabled: true,
      stream: true,
    },
  },
]);

function findRepoRoot(startDir) {
  let current = startDir;

  for (let i = 0; i < 8; i += 1) {
    if (fs.existsSync(path.join(current, "pnpm-workspace.yaml"))) {
      return current;
    }

    const parent = path.dirname(current);

    if (parent === current) {
      break;
    }

    current = parent;
  }

  return path.resolve(__dirname, "../../../..");
}

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) {
    return;
  }

  const content = fs.readFileSync(filePath, "utf8");

  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();

    if (!trimmed || trimmed.startsWith("#") || !trimmed.includes("=")) {
      continue;
    }

    const index = trimmed.indexOf("=");
    const key = trimmed.slice(0, index).trim();
    let value = trimmed.slice(index + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

function loadEnvironment() {
  const repoRoot = findRepoRoot(__dirname);
  const appRoot = path.resolve(__dirname, "../..");

  loadEnvFile(path.join(repoRoot, ".env.local"));
  loadEnvFile(path.join(appRoot, ".env.local"));
}

function getVerifyLicenseUrl() {
  const explicit = process.env.CORRA_VERIFY_LICENSE_URL;

  if (explicit && explicit.trim()) {
    return explicit.trim();
  }

  const supabaseUrl =
    process.env.VITE_SUPABASE_URL ||
    process.env.SUPABASE_URL ||
    "";

  if (supabaseUrl.trim()) {
    return `${supabaseUrl.replace(/\/$/, "")}/functions/v1/verify-license`;
  }

  return DEFAULT_VERIFY_LICENSE_URL;
}

function getLicenseCachePath() {
  return path.join(app.getPath("userData"), "license-cache.json");
}

function readJsonFile(filePath) {
  try {
    if (!fs.existsSync(filePath)) {
      return null;
    }

    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function writeJsonFile(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), {
    recursive: true,
  });

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
}

function createDeviceFingerprint() {
  const cpuModel = os.cpus()?.[0]?.model ?? "unknown-cpu";

  const raw = [
    os.hostname(),
    os.platform(),
    os.arch(),
    cpuModel,
    app.getPath("userData"),
  ].join("|");

  return crypto
    .createHash("sha256")
    .update(raw)
    .digest("hex");
}

function getDeviceInfo() {
  return {
    fingerprint: createDeviceFingerprint(),
    deviceName: os.hostname(),
    platform: "WINDOWS_ELECTRON",
    osPlatform: os.platform(),
    osRelease: os.release(),
    arch: os.arch(),
  };
}

function sanitizeLicenseCode(value) {
  return String(value ?? "")
    .trim()
    .replace(/\s+/g, "")
    .toUpperCase();
}

async function verifyLicense(input) {
  const licenseCode = sanitizeLicenseCode(input?.licenseCode);

  if (!licenseCode) {
    return {
      valid: false,
      reason: "Missing licenseCode",
    };
  }

  const deviceInfo = getDeviceInfo();
  const verifyUrl = getVerifyLicenseUrl();

  const response = await fetch(verifyUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      licenseCode,
      deviceFingerprint: deviceInfo.fingerprint,
      deviceName: input?.deviceName || deviceInfo.deviceName,
      platform: deviceInfo.platform,
    }),
  });

  const text = await response.text();

  let data;

  try {
    data = JSON.parse(text);
  } catch {
    return {
      valid: false,
      reason: `Verify endpoint returned non-JSON response: HTTP ${response.status}`,
      raw: text,
    };
  }

  if (!response.ok) {
    return {
      valid: false,
      reason: data?.reason || data?.error || `HTTP ${response.status}`,
      detail: data?.detail,
      response: data,
    };
  }

  const result = {
    ...data,
    checkedAt: new Date().toISOString(),
    verifyUrl,
    deviceInfo,
  };

  if (data?.valid === true) {
    writeJsonFile(getLicenseCachePath(), result);
  }

  return result;
}

function readLicenseCache() {
  return readJsonFile(getLicenseCachePath());
}

function clearLicenseCache() {
  const filePath = getLicenseCachePath();

  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }

  return {
    ok: true,
  };
}


function ensureDirectory(directoryPath) {
  fs.mkdirSync(directoryPath, {
    recursive: true,
  });
}

function getBrandAssetsRoot() {
  return path.join(app.getPath("userData"), "brand-assets");
}

function getAssetDirectory(kind) {
  return path.join(getBrandAssetsRoot(), kind);
}

function getAssetUrl(kind, filename) {
  return `corra-asset://${kind}/${encodeURIComponent(filename)}`;
}

function sanitizeAssetFilename(filename) {
  const ext = path.extname(filename).toLowerCase();
  const base = path
    .basename(filename, ext)
    .replace(/[^a-zA-Z0-9-_]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80) || "background";

  return `${Date.now()}-${base}${ext}`;
}

function getBackgroundTypeFromExtension(filePath) {
  const ext = path.extname(filePath).toLowerCase();

  if (ext === ".mp4") {
    return "video";
  }

  return "image";
}

function isSupportedBackgroundExtension(filePath) {
  const ext = path.extname(filePath).toLowerCase();

  return [".png", ".jpg", ".jpeg", ".webp", ".mp4"].includes(ext);
}

function registerAssetProtocol() {
  protocol.handle("corra-asset", async (request) => {
    try {
      const url = new URL(request.url);
      const kind = url.hostname;
      const filename = decodeURIComponent(url.pathname.replace(/^\/+/, ""));

      if (!kind || !filename) {
        return new Response("Not found", {
          status: 404,
        });
      }

      const assetRoot = path.normalize(getAssetDirectory(kind));
      const filePath = path.normalize(path.join(assetRoot, filename));

      if (!filePath.startsWith(assetRoot)) {
        return new Response("Forbidden", {
          status: 403,
        });
      }

      if (!fs.existsSync(filePath)) {
        return new Response("Not found", {
          status: 404,
        });
      }

      return net.fetch(pathToFileURL(filePath).toString());
    } catch (error) {
      return new Response(error instanceof Error ? error.message : "Asset protocol error", {
        status: 500,
      });
    }
  });
}

async function pickBackgroundAsset() {
  const result = await dialog.showOpenDialog(mainWindow, {
    title: "Choose Corra Booth Background",
    properties: ["openFile"],
    filters: [
      {
        name: "Background Assets",
        extensions: ["png", "jpg", "jpeg", "webp", "mp4"],
      },
      {
        name: "Images",
        extensions: ["png", "jpg", "jpeg", "webp"],
      },
      {
        name: "Videos",
        extensions: ["mp4"],
      },
    ],
  });

  if (result.canceled || !result.filePaths.length) {
    return {
      cancelled: true,
    };
  }

  const sourcePath = result.filePaths[0];

  if (!isSupportedBackgroundExtension(sourcePath)) {
    return {
      cancelled: true,
      error: "Unsupported background file. Use PNG, JPG, WebP, or MP4.",
    };
  }

  const kind = "backgrounds";
  const targetDirectory = getAssetDirectory(kind);
  ensureDirectory(targetDirectory);

  const filename = sanitizeAssetFilename(sourcePath);
  const targetPath = path.join(targetDirectory, filename);

  fs.copyFileSync(sourcePath, targetPath);

  return {
    cancelled: false,
    sourcePath,
    targetPath,
    filename,
    url: getAssetUrl(kind, filename),
    backgroundType: getBackgroundTypeFromExtension(sourcePath),
  };
}

function registerIpcHandlers() {
  ipcMain.handle("corra:device-info", async () => {
    return getDeviceInfo();
  });

  ipcMain.handle("corra:license-verify", async (_event, input) => {
    try {
      return await verifyLicense(input);
    } catch (error) {
      return {
        valid: false,
        reason: error instanceof Error ? error.message : "Unknown license verification error",
      };
    }
  });

  ipcMain.handle("corra:license-read-cache", async () => {
    return readLicenseCache();
  });

  ipcMain.handle("corra:license-clear-cache", async () => {
    return clearLicenseCache();
  });

  ipcMain.handle("corra:asset-pick-background", async () => {
    try {
      return await pickBackgroundAsset();
    } catch (error) {
      return {
        cancelled: true,
        error: error instanceof Error ? error.message : "Unknown asset picker error",
      };
    }
  });
}

function createWindow() {
  const preloadPath = path.join(__dirname, "../preload/preload.cjs");

  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 1024,
    minHeight: 720,
    title: "Corra Booth",
    backgroundColor: "#111111",
    webPreferences: {
      preload: preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return {
      action: "deny",
    };
  });

  const devServerUrl =
    process.env.CORRA_BOOTH_UI_DEV_SERVER_URL || "http://127.0.0.1:5173";

  mainWindow.loadURL(devServerUrl);

  if (process.env.CORRA_OPEN_DEVTOOLS === "true") {
    mainWindow.webContents.openDevTools({
      mode: "detach",
    });
  }
}

loadEnvironment();

app.whenReady().then(() => {
  registerAssetProtocol();
  registerIpcHandlers();
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
