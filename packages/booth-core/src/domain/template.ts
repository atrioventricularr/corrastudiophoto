import type { BoothTemplate } from "@corra/shared";

export function createBoothTemplate(template: BoothTemplate): BoothTemplate {
  if (!template.id) throw new Error("Template ID is required.");
  if (!template.name) throw new Error("Template name is required.");
  if (!template.layoutId) throw new Error("Template layout ID is required.");

  if (template.canvasWidth <= 0 || template.canvasHeight <= 0) {
    throw new Error("Template canvas size must be positive.");
  }

  return template;
}
