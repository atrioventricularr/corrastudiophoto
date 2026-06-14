export function normalizeBaseUrl(baseUrl: string): string {
  const trimmed = baseUrl.trim();

  if (!trimmed) {
    throw new Error("Base URL is required.");
  }

  return trimmed.replace(/\/+$/, "");
}

export function appendQueryParams(
  url: string,
  params: Record<string, string | number | boolean | null | undefined>,
): string {
  const parsedUrl = new URL(url);

  for (const [key, value] of Object.entries(params)) {
    if (value !== null && value !== undefined) {
      parsedUrl.searchParams.set(key, String(value));
    }
  }

  return parsedUrl.toString();
}
