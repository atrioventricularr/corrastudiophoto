import type {
  ISODateTimeString,
  LicenseRecord,
  LicenseVerificationResult,
} from "@corra/shared";

export function isLicenseDateActive(
  activeFrom: ISODateTimeString,
  activeUntil: ISODateTimeString | null,
  now: Date = new Date(),
): boolean {
  const fromTime = new Date(activeFrom).getTime();

  if (Number.isNaN(fromTime)) {
    return false;
  }

  if (now.getTime() < fromTime) {
    return false;
  }

  if (!activeUntil) {
    return true;
  }

  const untilTime = new Date(activeUntil).getTime();

  if (Number.isNaN(untilTime)) {
    return false;
  }

  return now.getTime() <= untilTime;
}

export function verifyLicenseRecord(
  license: LicenseRecord | null,
  now: Date = new Date(),
): LicenseVerificationResult {
  if (!license) {
    return {
      license: null,
      isValid: false,
      reason: "NOT_FOUND",
    };
  }

  if (license.status === "SUSPENDED") {
    return {
      license,
      isValid: false,
      reason: "SUSPENDED",
    };
  }

  if (license.status === "CANCELLED") {
    return {
      license,
      isValid: false,
      reason: "CANCELLED",
    };
  }

  if (license.status === "PENDING") {
    return {
      license,
      isValid: false,
      reason: "PENDING",
    };
  }

  if (!isLicenseDateActive(license.activeFrom, license.activeUntil, now)) {
    return {
      license,
      isValid: false,
      reason: "EXPIRED",
    };
  }

  return {
    license,
    isValid: true,
    reason: "ACTIVE",
  };
}
