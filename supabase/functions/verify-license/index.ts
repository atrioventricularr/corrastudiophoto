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

type MayarLicenseDetail = {
  licenseCode?: string;
  status?: string;
  expiredAt?: string | null;
  transactionId?: string | null;
  productId?: string | null;
  customerId?: string | null;
  customerName?: string | null;
  customerEmail?: string | null;
  activationLimit?: string | number | null;
  useCount?: number | null;
  createdAt?: string | null;
  updatedAt?: string | null;
};

type MayarVerifyResponse = {
  statusCode?: number;
  isLicenseActive?: boolean;
  licenseCode?: MayarLicenseDetail | MayarLicenseDetail[] | null;
  message?: string;
  messages?: string;
  error?: string;
};

function invalid(reason: string, status = 200, extra: Record<string, unknown> = {}): Response {
  return jsonResponse({
    valid: false,
    reason,
    ...extra,
  }, status);
}

async function parseBody(req: Request): Promise<VerifyLicenseBody> {
  try {
    return await req.json();
  } catch {
    throw new Error("Invalid JSON body");
  }
}

function normalizeInput(value: string | undefined): string {
  return (value ?? "").trim();
}

function getRequiredSecret(name: string): string {
  const value = Deno.env.get(name);

  if (!value) {
    throw new Error(`Missing required secret: ${name}`);
  }

  return value;
}

function asMayarLicenseDetail(value: unknown): MayarLicenseDetail | null {
  if (!value) return null;

  if (Array.isArray(value)) {
    const first = value[0];
    if (first && typeof first === "object") {
      return first as MayarLicenseDetail;
    }
    return null;
  }

  if (typeof value === "object") {
    return value as MayarLicenseDetail;
  }

  return null;
}

function parseActiveUntil(expiredAt: string | null | undefined): string | null {
  if (!expiredAt) return null;

  const time = new Date(expiredAt).getTime();

  if (Number.isNaN(time)) {
    return null;
  }

  return new Date(time).toISOString();
}

function parseActiveFrom(createdAt: string | null | undefined): string {
  if (!createdAt) return new Date().toISOString();

  const time = new Date(createdAt).getTime();

  if (Number.isNaN(time)) {
    return new Date().toISOString();
  }

  return new Date(time).toISOString();
}

function parseActivationLimit(value: string | number | null | undefined): number {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.floor(value);
  }

  const raw = String(value ?? "").trim().toLowerCase();

  if (!raw) return 1;

  if (
    raw.includes("tidak terbatas") ||
    raw.includes("unlimited") ||
    raw.includes("infinite")
  ) {
    return 999999;
  }

  const numeric = Number(raw.replace(/[^0-9]/g, ""));

  if (Number.isFinite(numeric) && numeric > 0) {
    return Math.floor(numeric);
  }

  return 1;
}

async function verifyToMayar(licenseCode: string): Promise<{
  response: MayarVerifyResponse;
  detail: MayarLicenseDetail | null;
}> {
  const mayarApiKey = getRequiredSecret("MAYAR_API_KEY");
  const productId = getRequiredSecret("MAYAR_PRODUCT_ID");

  const mayarResponse = await fetch("https://api.mayar.id/software/v1/license/verify", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${mayarApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      licenseCode,
      productId,
    }),
  });

  const text = await mayarResponse.text();

  let json: MayarVerifyResponse;

  try {
    json = JSON.parse(text) as MayarVerifyResponse;
  } catch {
    throw new Error(`Mayar returned non-JSON response with status ${mayarResponse.status}`);
  }

  if (!mayarResponse.ok) {
    const message = json.message ?? json.messages ?? json.error ?? "Mayar verification failed";
    throw new Error(`${message} (${mayarResponse.status})`);
  }

  return {
    response: json,
    detail: asMayarLicenseDetail(json.licenseCode),
  };
}

function getMayarActiveStatus(response: MayarVerifyResponse, detail: MayarLicenseDetail | null): boolean {
  if (response.isLicenseActive !== true) {
    return false;
  }

  const status = (detail?.status ?? "").trim().toUpperCase();

  if (!status) {
    return true;
  }

  return status === "ACTIVE";
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

  let mayar: {
    response: MayarVerifyResponse;
    detail: MayarLicenseDetail | null;
  };

  try {
    mayar = await verifyToMayar(licenseCode);
  } catch (error) {
    return jsonResponse({
      valid: false,
      reason: "Mayar verification failed",
      detail: error instanceof Error ? error.message : "Unknown Mayar verification error",
    }, 502);
  }

  const mayarDetail = mayar.detail;
  const isMayarActive = getMayarActiveStatus(mayar.response, mayarDetail);

  if (!isMayarActive) {
    return invalid("Mayar license is not active", 200, {
      mayar: {
        statusCode: mayar.response.statusCode,
        isLicenseActive: mayar.response.isLicenseActive ?? false,
        licenseStatus: mayarDetail?.status ?? null,
        expiredAt: mayarDetail?.expiredAt ?? null,
      },
    });
  }

  const ownerEmail = mayarDetail?.customerEmail?.trim();

  if (!ownerEmail) {
    return invalid("Mayar license is active but customerEmail is missing", 502);
  }

  const activeFrom = parseActiveFrom(mayarDetail?.createdAt);
  const activeUntil = parseActiveUntil(mayarDetail?.expiredAt);
  const maxDevices = parseActivationLimit(mayarDetail?.activationLimit);

  const supabase = createSupabaseAdminClient();

  const { data: syncedLicense, error: syncLicenseError } = await supabase
    .from("licenses")
    .upsert({
      license_code: licenseCode,
      owner_email: ownerEmail,
      owner_name: mayarDetail?.customerName ?? null,
      status: "ACTIVE",
      mayar_transaction_id: mayarDetail?.transactionId ?? null,
      active_from: activeFrom,
      active_until: activeUntil,
      max_devices: maxDevices,
      metadata: {
        source: "mayar-license-verify",
        mayarProductId: mayarDetail?.productId ?? Deno.env.get("MAYAR_PRODUCT_ID") ?? null,
        mayarCustomerId: mayarDetail?.customerId ?? null,
        mayarActivationLimit: mayarDetail?.activationLimit ?? null,
        mayarUseCount: mayarDetail?.useCount ?? null,
        mayarStatusCode: mayar.response.statusCode ?? null,
        syncedAt: new Date().toISOString(),
      },
    }, {
      onConflict: "license_code",
    })
    .select("id, license_code, owner_email, owner_name, status, active_from, active_until, max_devices, billing_cycle")
    .single();

  if (syncLicenseError || !syncedLicense) {
    return jsonResponse({
      valid: false,
      reason: "Failed to sync Mayar license to Supabase",
      detail: syncLicenseError?.message ?? "Unknown license sync error",
    }, 500);
  }

  const { data: existingDevice, error: existingDeviceError } = await supabase
    .from("booth_devices")
    .select("id")
    .eq("license_id", syncedLicense.id)
    .eq("device_fingerprint", deviceFingerprint)
    .maybeSingle();

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
        license_id: syncedLicense.id,
        device_id: existingDevice.id,
        action: "VERIFIED",
        metadata: {
          source: "verify-license-mayar",
          mayarProductId: mayarDetail?.productId ?? null,
        },
      });

    return jsonResponse({
      valid: true,
      source: "mayar",
      license: {
        id: syncedLicense.id,
        licenseCode: syncedLicense.license_code,
        ownerEmail: syncedLicense.owner_email,
        ownerName: syncedLicense.owner_name,
        billingCycle: syncedLicense.billing_cycle,
        activeFrom: syncedLicense.active_from,
        activeUntil: syncedLicense.active_until,
        maxDevices: syncedLicense.max_devices,
      },
      mayar: {
        isLicenseActive: mayar.response.isLicenseActive ?? true,
        status: mayarDetail?.status ?? null,
        expiredAt: mayarDetail?.expiredAt ?? null,
        transactionId: mayarDetail?.transactionId ?? null,
        productId: mayarDetail?.productId ?? null,
        activationLimit: mayarDetail?.activationLimit ?? null,
        useCount: mayarDetail?.useCount ?? null,
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
    .eq("license_id", syncedLicense.id);

  if (countError) {
    return jsonResponse({
      valid: false,
      reason: "Device count failed",
      detail: countError.message,
    }, 500);
  }

  if ((count ?? 0) >= syncedLicense.max_devices) {
    await supabase
      .from("license_activations")
      .insert({
        license_id: syncedLicense.id,
        action: "DEVICE_LIMIT_REACHED",
        metadata: {
          source: "verify-license-mayar",
          deviceFingerprint,
          deviceName,
          platform,
          mayarActivationLimit: mayarDetail?.activationLimit ?? null,
        },
      });

    return invalid("Device limit reached", 200, {
      maxDevices: syncedLicense.max_devices,
      currentDevices: count ?? 0,
    });
  }

  const deviceId = `device_${crypto.randomUUID()}`;

  const { data: createdDevice, error: createDeviceError } = await supabase
    .from("booth_devices")
    .insert({
      id: deviceId,
      license_id: syncedLicense.id,
      device_fingerprint: deviceFingerprint,
      device_name: deviceName,
      platform,
      last_seen_at: new Date().toISOString(),
      metadata: {
        source: "verify-license-mayar",
        mayarProductId: mayarDetail?.productId ?? null,
      },
    })
    .select("id")
    .single();

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
      license_id: syncedLicense.id,
      device_id: createdDevice.id,
      action: "ACTIVATED",
      metadata: {
        source: "verify-license-mayar",
        mayarProductId: mayarDetail?.productId ?? null,
      },
    });

  return jsonResponse({
    valid: true,
    source: "mayar",
    license: {
      id: syncedLicense.id,
      licenseCode: syncedLicense.license_code,
      ownerEmail: syncedLicense.owner_email,
      ownerName: syncedLicense.owner_name,
      billingCycle: syncedLicense.billing_cycle,
      activeFrom: syncedLicense.active_from,
      activeUntil: syncedLicense.active_until,
      maxDevices: syncedLicense.max_devices,
    },
    mayar: {
      isLicenseActive: mayar.response.isLicenseActive ?? true,
      status: mayarDetail?.status ?? null,
      expiredAt: mayarDetail?.expiredAt ?? null,
      transactionId: mayarDetail?.transactionId ?? null,
      productId: mayarDetail?.productId ?? null,
      activationLimit: mayarDetail?.activationLimit ?? null,
      useCount: mayarDetail?.useCount ?? null,
    },
    device: {
      id: createdDevice.id,
      alreadyActivated: false,
    },
  });
});
