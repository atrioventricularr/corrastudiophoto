import { handleCors, jsonResponse } from "../_shared/cors.ts";
import { createSupabaseAdminClient } from "../_shared/supabase-admin.ts";

type VerifyLicenseBody = {
  licenseCode?: string;
  license_code?: string;
  deviceFingerprint?: string;
  device_fingerprint?: string;
  deviceName?: string;
  device_name?: string;
  platform?: string;
};

type LicenseRow = {
  id: string;
  license_code: string;
  owner_email: string;
  owner_name: string | null;
  status: string;
  active_from: string | null;
  active_until: string | null;
  max_devices: number;
  billing_cycle: string;
};

function invalid(reason: string, status = 200): Response {
  return jsonResponse({
    valid: false,
    reason,
  }, status);
}

async function parseBody(req: Request): Promise<VerifyLicenseBody> {
  try {
    return await req.json();
  } catch {
    throw new Error("Invalid JSON body");
  }
}

function isDateActive(activeFrom: string | null, activeUntil: string | null): boolean {
  const now = Date.now();

  if (activeFrom && new Date(activeFrom).getTime() > now) {
    return false;
  }

  if (activeUntil && new Date(activeUntil).getTime() < now) {
    return false;
  }

  return true;
}

function normalizeInput(value: string | undefined): string {
  return (value ?? "").trim();
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return jsonResponse({
      valid: false,
      reason: "Method not allowed",
    }, 405);
  }

  let body: VerifyLicenseBody;

  try {
    body = await parseBody(req);
  } catch (error) {
    return invalid(error instanceof Error ? error.message : "Invalid request body", 400);
  }

  const licenseCode = normalizeInput(body.licenseCode ?? body.license_code);
  const deviceFingerprint = normalizeInput(body.deviceFingerprint ?? body.device_fingerprint);
  const deviceName = normalizeInput(body.deviceName ?? body.device_name) || null;
  const platform = normalizeInput(body.platform) || "WINDOWS_ELECTRON";

  if (!licenseCode) {
    return invalid("Missing licenseCode", 400);
  }

  if (!deviceFingerprint) {
    return invalid("Missing deviceFingerprint", 400);
  }

  const supabase = createSupabaseAdminClient();

  const { data: license, error: licenseError } = await supabase
    .from("licenses")
    .select("id, license_code, owner_email, owner_name, status, active_from, active_until, max_devices, billing_cycle")
    .eq("license_code", licenseCode)
    .maybeSingle<LicenseRow>();

  if (licenseError) {
    return jsonResponse({
      valid: false,
      reason: "License lookup failed",
      detail: licenseError.message,
    }, 500);
  }

  if (!license) {
    return invalid("License not found");
  }

  if (license.status !== "ACTIVE") {
    return invalid(`License status is ${license.status}`);
  }

  if (!isDateActive(license.active_from, license.active_until)) {
    return invalid("License is outside active date window");
  }

  const { data: existingDevice, error: existingDeviceError } = await supabase
    .from("booth_devices")
    .select("id")
    .eq("license_id", license.id)
    .eq("device_fingerprint", deviceFingerprint)
    .maybeSingle<{ id: string }>();

  if (existingDeviceError) {
    return jsonResponse({
      valid: false,
      reason: "Device lookup failed",
      detail: existingDeviceError.message,
    }, 500);
  }

  if (existingDevice) {
    const { error: updateDeviceError } = await supabase
      .from("booth_devices")
      .update({
        device_name: deviceName,
        platform,
        last_seen_at: new Date().toISOString(),
      })
      .eq("id", existingDevice.id);

    if (updateDeviceError) {
      return jsonResponse({
        valid: false,
        reason: "Device update failed",
        detail: updateDeviceError.message,
      }, 500);
    }

    await supabase
      .from("license_activations")
      .insert({
        license_id: license.id,
        device_id: existingDevice.id,
        action: "VERIFIED",
        metadata: {
          source: "verify-license",
        },
      });

    return jsonResponse({
      valid: true,
      license: {
        id: license.id,
        licenseCode: license.license_code,
        ownerEmail: license.owner_email,
        ownerName: license.owner_name,
        billingCycle: license.billing_cycle,
        activeFrom: license.active_from,
        activeUntil: license.active_until,
        maxDevices: license.max_devices,
      },
      device: {
        id: existingDevice.id,
        alreadyActivated: true,
      },
    });
  }

  const { count, error: countError } = await supabase
    .from("booth_devices")
    .select("id", {
      count: "exact",
      head: true,
    })
    .eq("license_id", license.id);

  if (countError) {
    return jsonResponse({
      valid: false,
      reason: "Device count failed",
      detail: countError.message,
    }, 500);
  }

  if ((count ?? 0) >= license.max_devices) {
    await supabase
      .from("license_activations")
      .insert({
        license_id: license.id,
        action: "DEVICE_LIMIT_REACHED",
        metadata: {
          source: "verify-license",
          deviceFingerprint,
          deviceName,
          platform,
        },
      });

    return invalid("Device limit reached");
  }

  const deviceId = `device_${crypto.randomUUID()}`;

  const { data: createdDevice, error: createDeviceError } = await supabase
    .from("booth_devices")
    .insert({
      id: deviceId,
      license_id: license.id,
      device_fingerprint: deviceFingerprint,
      device_name: deviceName,
      platform,
      last_seen_at: new Date().toISOString(),
      metadata: {
        source: "verify-license",
      },
    })
    .select("id")
    .single<{ id: string }>();

  if (createDeviceError || !createdDevice) {
    return jsonResponse({
      valid: false,
      reason: "Device activation failed",
      detail: createDeviceError?.message ?? "Unknown device activation error",
    }, 500);
  }

  await supabase
    .from("license_activations")
    .insert({
      license_id: license.id,
      device_id: createdDevice.id,
      action: "ACTIVATED",
      metadata: {
        source: "verify-license",
      },
    });

  return jsonResponse({
    valid: true,
    license: {
      id: license.id,
      licenseCode: license.license_code,
      ownerEmail: license.owner_email,
      ownerName: license.owner_name,
      billingCycle: license.billing_cycle,
      activeFrom: license.active_from,
      activeUntil: license.active_until,
      maxDevices: license.max_devices,
    },
    device: {
      id: createdDevice.id,
      alreadyActivated: false,
    },
  });
});
