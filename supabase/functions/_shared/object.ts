type JsonObject = Record<string, unknown>;

export function asObject(value: unknown): JsonObject {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as JsonObject;
  }

  return {};
}

export function getPath(source: unknown, path: string): unknown {
  const keys = path.split(".");
  let current: unknown = source;

  for (const key of keys) {
    if (!current || typeof current !== "object" || Array.isArray(current)) {
      return undefined;
    }

    current = (current as JsonObject)[key];
  }

  return current;
}

export function findString(source: unknown, paths: string[]): string | null {
  for (const path of paths) {
    const value = getPath(source, path);

    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }

    if (typeof value === "number" && Number.isFinite(value)) {
      return String(value);
    }
  }

  return null;
}

export function normalizeUpper(value: string | null): string {
  return (value ?? "").trim().toUpperCase();
}
