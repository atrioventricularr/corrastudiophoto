import { verifyLicenseRecord } from "../domain/license";
import type { LicenseRepositoryPort } from "../ports/license-repository.port";

export interface VerifyLicenseInput {
  licenseCode: string;
  now?: Date;
}

export async function verifyLicenseUseCase(
  licenseRepository: LicenseRepositoryPort,
  input: VerifyLicenseInput,
) {
  if (!input.licenseCode.trim()) {
    throw new Error("License code is required.");
  }

  const license = await licenseRepository.findByCode(input.licenseCode.trim());

  return verifyLicenseRecord(license, input.now ?? new Date());
}
