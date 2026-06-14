import type { LicenseRecord } from "@corra/shared";

export interface LicenseRepositoryPort {
  findByCode(licenseCode: string): Promise<LicenseRecord | null>;
  bindDevice?(licenseCode: string, deviceId: string): Promise<void>;
}
