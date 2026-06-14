import type { CorraId, ISODateTimeString } from "./common.types";

export type LicenseStatus =
  | "PENDING"
  | "ACTIVE"
  | "EXPIRED"
  | "SUSPENDED"
  | "CANCELLED";

export type LicenseBillingCycle = "MONTHLY" | "YEARLY" | "TRIAL" | "LIFETIME";

export interface LicenseRecord {
  id: CorraId;
  licenseCode: string;
  ownerEmail: string;
  ownerName?: string;
  status: LicenseStatus;
  billingCycle: LicenseBillingCycle;
  mayarCustomerId?: string;
  mayarTransactionId?: string;
  mayarSubscriptionId?: string;
  activeFrom: ISODateTimeString;
  activeUntil: ISODateTimeString | null;
  maxDevices: number;
  createdAt: ISODateTimeString;
  updatedAt: ISODateTimeString;
}

export interface LicenseVerificationResult {
  license: LicenseRecord | null;
  isValid: boolean;
  reason:
    | "ACTIVE"
    | "NOT_FOUND"
    | "EXPIRED"
    | "SUSPENDED"
    | "CANCELLED"
    | "PENDING"
    | "DEVICE_LIMIT_REACHED";
}
