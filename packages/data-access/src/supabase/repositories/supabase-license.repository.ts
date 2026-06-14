import type { LicenseRepositoryPort } from "@corra/booth-core";
import type { LicenseRecord } from "@corra/shared";
import { mapLicenseRowToRecord } from "../mappers/license.mapper";
import type { CorraSupabaseClient } from "../supabase-client";

export class SupabaseLicenseRepository implements LicenseRepositoryPort {
  constructor(private readonly client: CorraSupabaseClient) {}

  async findByCode(licenseCode: string): Promise<LicenseRecord | null> {
    const normalizedCode = licenseCode.trim();

    if (!normalizedCode) {
      return null;
    }

    const { data, error } = await this.client
      .from("licenses")
      .select("*")
      .eq("license_code", normalizedCode)
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to find license: ${error.message}`);
    }

    return data ? mapLicenseRowToRecord(data) : null;
  }

  async bindDevice(licenseCode: string, deviceId: string): Promise<void> {
    const license = await this.findByCode(licenseCode);

    if (!license) {
      throw new Error("Cannot bind device because license was not found.");
    }

    const { error } = await this.client.from("booth_devices").upsert({
      id: deviceId,
      license_id: license.id,
      device_fingerprint: deviceId,
      platform: "WINDOWS_ELECTRON",
      last_seen_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });

    if (error) {
      throw new Error(`Failed to bind device: ${error.message}`);
    }
  }
}
