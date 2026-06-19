import {
  defaultActivePhotoTemplate,
  defaultPhotoTemplates,
} from './default-templates';
import type {
  PhotoTemplate,
} from './types';

const TEMPLATES_KEY = 'corra.photoTemplates.v1';
const ACTIVE_TEMPLATE_ID_KEY = 'corra.activePhotoTemplateId.v1';

export function loadPhotoTemplates(): PhotoTemplate[] {
  if (typeof window === 'undefined') return defaultPhotoTemplates;

  try {
    const raw = window.localStorage.getItem(TEMPLATES_KEY);
    const parsed = raw ? JSON.parse(raw) : null;

    if (!Array.isArray(parsed) || parsed.length === 0) {
      return defaultPhotoTemplates;
    }

    return parsed as PhotoTemplate[];
  } catch {
    return defaultPhotoTemplates;
  }
}

export function savePhotoTemplates(templates: PhotoTemplate[]): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(TEMPLATES_KEY, JSON.stringify(templates));
}

export function loadActivePhotoTemplateId(): string {
  if (typeof window === 'undefined') return defaultActivePhotoTemplate.id;

  return (
    window.localStorage.getItem(ACTIVE_TEMPLATE_ID_KEY) ||
    defaultActivePhotoTemplate.id
  );
}

export function saveActivePhotoTemplateId(templateId: string): void {
  if (typeof window === 'undefined') return;
  window.localStorage.setItem(ACTIVE_TEMPLATE_ID_KEY, templateId);
}

export function clearTemplateStorage(): void {
  if (typeof window === 'undefined') return;

  window.localStorage.removeItem(TEMPLATES_KEY);
  window.localStorage.removeItem(ACTIVE_TEMPLATE_ID_KEY);
}
