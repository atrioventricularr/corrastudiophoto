const fs = require('fs');
const path = require('path');

function safeSegment(value, fallback = 'item') {
  return String(value || fallback)
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 120) || fallback;
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function outputRoot(app) {
  const root = path.join(app.getPath('userData'), 'corra-booth-output');
  ensureDir(root);
  return root;
}

function assertInsideRoot(root, targetPath) {
  const resolvedRoot = path.resolve(root);
  const resolvedTarget = path.resolve(targetPath);
  if (!resolvedTarget.startsWith(resolvedRoot)) {
    throw new Error('Unsafe file path outside Corra output root.');
  }
  return resolvedTarget;
}

function parseDataUrl(dataUrl) {
  const match = /^data:([^;,]+)?(;base64)?,(.*)$/s.exec(String(dataUrl || ''));
  if (!match) throw new Error('Invalid data URL.');

  const mimeType = match[1] || 'application/octet-stream';
  const isBase64 = Boolean(match[2]);
  const body = match[3] || '';

  return {
    mimeType,
    buffer: isBase64
      ? Buffer.from(body, 'base64')
      : Buffer.from(decodeURIComponent(body), 'utf8'),
  };
}

function inferExtension(filename, mimeType) {
  const ext = path.extname(String(filename || '')).replace('.', '');
  if (ext) return ext;
  if (mimeType === 'image/png') return 'png';
  if (mimeType === 'image/jpeg') return 'jpg';
  if (mimeType === 'image/webp') return 'webp';
  if (mimeType === 'image/gif') return 'gif';
  if (mimeType === 'application/json') return 'json';
  return 'bin';
}

function listFilesRecursive(root, dir, out = []) {
  if (!fs.existsSync(dir)) return out;

  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const entryPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      listFilesRecursive(root, entryPath, out);
      continue;
    }

    const stat = fs.statSync(entryPath);
    out.push({
      path: entryPath,
      relativePath: path.relative(root, entryPath),
      filename: entry.name,
      sizeBytes: stat.size,
      modifiedAt: stat.mtime.toISOString(),
    });
  }

  return out;
}

function registerCorraDiskPersistence({ ipcMain, app, shell }) {
  if (!ipcMain || !app) {
    console.warn('[corra-disk] Missing ipcMain/app. Disk persistence skipped.');
    return;
  }

  const handle = (channel, listener) => {
    try {
      ipcMain.removeHandler(channel);
    } catch (_) {}
    ipcMain.handle(channel, listener);
  };

  handle('corra:disk-get-root', async () => ({ ok: true, rootPath: outputRoot(app) }));

  handle('corra:disk-open-output-folder', async (_event, payload = {}) => {
    const root = outputRoot(app);
    const sessionId = safeSegment(payload.sessionId || '');
    const target = sessionId ? path.join(root, sessionId) : root;
    ensureDir(target);
    if (shell && typeof shell.openPath === 'function') {
      const error = await shell.openPath(target);
      if (error) throw new Error(error);
    }
    return { ok: true, path: target };
  });

  handle('corra:disk-save-data-url', async (_event, payload = {}) => {
    const root = outputRoot(app);
    const sessionId = safeSegment(payload.sessionId || 'unknown-session');
    const kind = safeSegment(payload.kind || 'asset');
    const originalName = safeSegment(payload.filename || `${kind}-${Date.now()}`);
    const parsed = parseDataUrl(payload.dataUrl);
    const ext = inferExtension(originalName, parsed.mimeType);
    const baseName = path.basename(originalName, path.extname(originalName));
    const filename = `${safeSegment(baseName)}-${Date.now()}.${ext}`;
    const dir = assertInsideRoot(root, path.join(root, sessionId, kind));
    ensureDir(dir);

    const filePath = assertInsideRoot(root, path.join(dir, filename));
    fs.writeFileSync(filePath, parsed.buffer);

    const stat = fs.statSync(filePath);
    const record = {
      ok: true,
      id: `disk-${Date.now()}-${Math.random().toString(16).slice(2)}`,
      sessionId,
      kind,
      filename,
      mimeType: parsed.mimeType,
      sizeBytes: stat.size,
      absolutePath: filePath,
      relativePath: path.relative(root, filePath),
      savedAt: new Date().toISOString(),
      metadata: payload.metadata || {},
    };

    fs.writeFileSync(`${filePath}.meta.json`, JSON.stringify(record, null, 2));
    return record;
  });

  handle('corra:disk-save-text-file', async (_event, payload = {}) => {
    const root = outputRoot(app);
    const sessionId = safeSegment(payload.sessionId || 'unknown-session');
    const kind = safeSegment(payload.kind || 'manifest');
    const filename = safeSegment(payload.filename || `${kind}-${Date.now()}.json`);
    const dir = assertInsideRoot(root, path.join(root, sessionId, kind));
    ensureDir(dir);

    const filePath = assertInsideRoot(root, path.join(dir, filename));
    fs.writeFileSync(filePath, String(payload.text || ''), 'utf8');
    const stat = fs.statSync(filePath);

    return {
      ok: true,
      id: `disk-text-${Date.now()}-${Math.random().toString(16).slice(2)}`,
      sessionId,
      kind,
      filename,
      mimeType: payload.mimeType || 'text/plain',
      sizeBytes: stat.size,
      absolutePath: filePath,
      relativePath: path.relative(root, filePath),
      savedAt: new Date().toISOString(),
      metadata: payload.metadata || {},
    };
  });

  handle('corra:disk-list-session-files', async (_event, payload = {}) => {
    const root = outputRoot(app);
    const sessionId = safeSegment(payload.sessionId || '');
    const target = sessionId ? path.join(root, sessionId) : root;
    assertInsideRoot(root, target);
    return { ok: true, rootPath: root, files: listFilesRecursive(root, target).slice(-1000) };
  });

  handle('corra:disk-delete-file', async (_event, payload = {}) => {
    const root = outputRoot(app);
    const target = assertInsideRoot(root, path.join(root, String(payload.relativePath || '')));
    if (fs.existsSync(target)) fs.unlinkSync(target);
    const metaPath = `${target}.meta.json`;
    if (fs.existsSync(metaPath)) fs.unlinkSync(metaPath);
    return { ok: true, relativePath: path.relative(root, target) };
  });

  handle('corra:disk-cleanup-older-than-days', async (_event, payload = {}) => {
    const root = outputRoot(app);
    const days = Math.max(1, Number(payload.days || 30));
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;
    const files = listFilesRecursive(root, root);
    let deleted = 0;

    for (const file of files) {
      if (new Date(file.modifiedAt).getTime() < cutoff) {
        const target = assertInsideRoot(root, file.path);
        if (fs.existsSync(target)) {
          fs.unlinkSync(target);
          deleted += 1;
        }
      }
    }

    return { ok: true, deletedCount: deleted, days };
  });

  console.log('[corra-disk] Disk persistence IPC registered.');
}

module.exports = { registerCorraDiskPersistence };
