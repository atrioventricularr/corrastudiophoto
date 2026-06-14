import { DOWNLOAD_PAGE_QUERY_PARAM } from "@corra/shared";
import { appendQueryParams, normalizeBaseUrl } from "../utils/url";

export interface BuildDownloadUrlInput {
  baseUrl: string;
  photoId: string;
  sessionId?: string;
  frameId?: string;
  downloadToken?: string;
}

export function buildDownloadUrl(input: BuildDownloadUrlInput): string {
  const baseUrl = normalizeBaseUrl(input.baseUrl);

  if (!input.photoId.trim()) {
    throw new Error("Photo ID is required to build download URL.");
  }

  return appendQueryParams(baseUrl, {
    [DOWNLOAD_PAGE_QUERY_PARAM]: input.photoId.trim(),
    sessionId: input.sessionId,
    frameId: input.frameId,
    token: input.downloadToken,
  });
}
