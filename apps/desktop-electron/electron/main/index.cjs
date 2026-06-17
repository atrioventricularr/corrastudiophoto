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


function getSecureVaultPath() {
  return path.join(app.getPath("userData"), "secure-vault.json");
}

function getSecureVaultKey() {
  const raw = [
    createDeviceFingerprint(),
    app.getPath("userData"),
    "corra-secure-vault-v1",
  ].join("|");

  return crypto.createHash("sha256").update(raw).digest();
}

function encryptSecretValue(value) {
  const iv = crypto.randomBytes(12);
  const key = getSecureVaultKey();
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([
    cipher.update(String(value), "utf8"),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();

  return {
    iv: iv.toString("base64"),
    tag: tag.toString("base64"),
    ciphertext: encrypted.toString("base64"),
  };
}

function decryptSecretValue(payload) {
  const key = getSecureVaultKey();
  const decipher = crypto.createDecipheriv(
    "aes-256-gcm",
    key,
    Buffer.from(payload.iv, "base64"),
  );

  decipher.setAuthTag(Buffer.from(payload.tag, "base64"));

  const decrypted = Buffer.concat([
    decipher.update(Buffer.from(payload.ciphertext, "base64")),
    decipher.final(),
  ]);

  return decrypted.toString("utf8");
}

function readSecureVault() {
  const vaultPath = getSecureVaultPath();

  if (!fs.existsSync(vaultPath)) {
    return {
      version: 1,
      items: {},
    };
  }

  try {
    const parsed = JSON.parse(fs.readFileSync(vaultPath, "utf8"));

    return {
      version: 1,
      items: parsed.items || {},
    };
  } catch {
    return {
      version: 1,
      items: {},
    };
  }
}

function writeSecureVault(vault) {
  const vaultPath = getSecureVaultPath();

  ensureDirectory(path.dirname(vaultPath));

  fs.writeFileSync(
    vaultPath,
    JSON.stringify(
      {
        version: 1,
        items: vault.items || {},
      },
      null,
      2,
    ),
  );
}

function maskSecret(value) {
  const stringValue = String(value || "");

  if (!stringValue) {
    return "";
  }

  if (stringValue.length <= 8) {
    return "••••";
  }

  return `${stringValue.slice(0, 3)}••••${stringValue.slice(-4)}`;
}

function getSecretStatus(secretKey) {
  const vault = readSecureVault();
  const item = vault.items[secretKey];

  if (!item) {
    return {
      key: secretKey,
      configured: false,
      label: null,
      maskedValue: "",
      updatedAt: null,
    };
  }

  let maskedValue = "••••";

  try {
    maskedValue = maskSecret(decryptSecretValue(item.encrypted));
  } catch {
    maskedValue = "••••";
  }

  return {
    key: secretKey,
    configured: true,
    label: item.label || secretKey,
    maskedValue,
    updatedAt: item.updatedAt || null,
  };
}

function setSecretValue(secretKey, secretValue, label) {
  if (!secretKey || !String(secretKey).trim()) {
    throw new Error("Missing secret key.");
  }

  if (!secretValue || !String(secretValue).trim()) {
    throw new Error("Missing secret value.");
  }

  const vault = readSecureVault();

  vault.items[secretKey] = {
    label: label || secretKey,
    encrypted: encryptSecretValue(secretValue),
    updatedAt: new Date().toISOString(),
  };

  writeSecureVault(vault);

  return getSecretStatus(secretKey);
}

function deleteSecretValue(secretKey) {
  const vault = readSecureVault();

  delete vault.items[secretKey];

  writeSecureVault(vault);

  return {
    key: secretKey,
    configured: false,
    label: null,
    maskedValue: "",
    updatedAt: null,
  };
}

function listSecretStatuses() {
  const vault = readSecureVault();

  return Object.keys(vault.items || {}).map((secretKey) =>
    getSecretStatus(secretKey),
  );
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

  ipcMain.handle("corra:vault-set-secret", async (_event, input) => {
    try {
      return setSecretValue(input?.key, input?.value, input?.label);
    } catch (error) {
      return {
        key: input?.key || "",
        configured: false,
        label: input?.label || null,
        maskedValue: "",
        updatedAt: null,
        error: error instanceof Error ? error.message : "Unknown vault set error",
      };
    }
  });

  ipcMain.handle("corra:vault-get-secret-status", async (_event, input) => {
    try {
      return getSecretStatus(input?.key);
    } catch (error) {
      return {
        key: input?.key || "",
        configured: false,
        label: null,
        maskedValue: "",
        updatedAt: null,
        error: error instanceof Error ? error.message : "Unknown vault status error",
      };
    }
  });

  ipcMain.handle("corra:vault-delete-secret", async (_event, input) => {
    try {
      return deleteSecretValue(input?.key);
    } catch (error) {
      return {
        key: input?.key || "",
        configured: false,
        label: null,
        maskedValue: "",
        updatedAt: null,
        error: error instanceof Error ? error.message : "Unknown vault delete error",
      };
    }
  });

  ipcMain.handle("corra:vault-list-secret-statuses", async () => {
    try {
      return listSecretStatuses();
    } catch {
      return [];
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
