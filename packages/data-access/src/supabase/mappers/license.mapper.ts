import type { LicenseRecord } from "@corra/shared";
import type { LicenseRow } from "../database.types";

export function mapLicenseRowToRecord(row: LicenseRow): LicenseRecord {
  return {
    id: row.id,
    licenseCode: row.license_code,
    ownerEmail: row.owner_email,
    ownerName: row.owner_name ?? undefined,
    status: row.status,
    billingCycle: row.billing_cycle,
    mayarCustomerId: row.mayar_customer_id ?? undefined,
    mayarTransactionId: row.mayar_transaction_id ?? undefined,
    mayarSubscriptionId: row.mayar_subscription_id ?? undefined,
    activeFrom: row.active_from,
    activeUntil: row.active_until,
    maxDevices: row.max_devices,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
