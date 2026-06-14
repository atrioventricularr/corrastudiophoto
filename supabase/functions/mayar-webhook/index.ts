import { handleCors, jsonResponse } from "../_shared/cors.ts";
import { createSupabaseAdminClient } from "../_shared/supabase-admin.ts";
import { asObject, findString, normalizeUpper } from "../_shared/object.ts";

const PAID_STATUSES = new Set([
  "PAID",
  "SUCCESS",
  "SUCCEEDED",
  "SETTLED",
  "COMPLETED",
  "ACTIVE",
]);

function addDays(date: Date, days: number): string {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next.toISOString();
}

function createLicenseCode(): string {
  return `CORRA-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
}

function createDeterministicEventId(
  eventId: string | null,
  transactionId: string | null,
  eventType: string | null,
): string {
  if (eventId) return eventId;
  if (transactionId) return `mayar-${transactionId}-${eventType ?? "event"}`;
  return `mayar-${crypto.randomUUID()}`;
}

function getBillingCycle(payload: unknown): "MONTHLY" | "YEARLY" | "TRIAL" | "LIFETIME" {
  const raw = normalizeUpper(findString(payload, [
    "billing_cycle",
    "billingCycle",
    "metadata.billing_cycle",
    "metadata.billingCycle",
    "data.billing_cycle",
    "data.billingCycle",
    "data.metadata.billing_cycle",
    "data.metadata.billingCycle",
  ]));

  if (raw === "YEARLY" || raw === "ANNUAL") return "YEARLY";
  if (raw === "TRIAL") return "TRIAL";
  if (raw === "LIFETIME") return "LIFETIME";

  return "MONTHLY";
}

function getActiveUntil(billingCycle: string): string | null {
  const now = new Date();

  if (billingCycle === "YEARLY") return addDays(now, 365);
  if (billingCycle === "TRIAL") return addDays(now, 14);
  if (billingCycle === "LIFETIME") return null;

  return addDays(now, 30);
}

async function parseJson(req: Request): Promise<Record<string, unknown>> {
  try {
    return asObject(await req.json());
  } catch {
    throw new Error("Invalid JSON body");
  }
}

async function authorizeWebhook(req: Request): Promise<boolean> {
  const secret = Deno.env.get("MAYAR_WEBHOOK_SECRET");

  if (!secret) {
    return true;
  }

  const url = new URL(req.url);
  const fromHeader = req.headers.get("x-corra-webhook-secret");
  const fromQuery = url.searchParams.get("secret");

  return fromHeader === secret || fromQuery === secret;
}

function extractPayloadInfo(payload: Record<string, unknown>) {
  const eventType = findString(payload, [
    "event",
    "type",
    "event_type",
    "eventType",
    "data.event",
    "data.type",
    "data.event_type",
    "data.eventType",
  ]);

  const rawEventId = findString(payload, [
    "id",
    "event_id",
    "eventId",
    "webhook_id",
    "webhookId",
    "webhookHistoryId",
    "data.id",
    "data.event_id",
    "data.eventId",
    "data.webhook_id",
    "data.webhookId",
    "data.webhookHistoryId",
  ]);

  const transactionId = findString(payload, [
    "transaction_id",
    "transactionId",
    "payment_id",
    "paymentId",
    "invoice_id",
    "invoiceId",
    "order_id",
    "orderId",
    "data.transaction_id",
    "data.transactionId",
    "data.payment_id",
    "data.paymentId",
    "data.invoice_id",
    "data.invoiceId",
    "data.order_id",
    "data.orderId",
  ]);

  const eventId = createDeterministicEventId(rawEventId, transactionId, eventType);

  const rawStatus = findString(payload, [
    "status",
    "payment_status",
    "paymentStatus",
    "transaction_status",
    "transactionStatus",
    "data.status",
    "data.payment_status",
    "data.paymentStatus",
    "data.transaction_status",
    "data.transactionStatus",
  ]);

  const ownerEmail = findString(payload, [
    "email",
    "customer_email",
    "customerEmail",
    "buyer_email",
    "buyerEmail",
    "data.email",
    "data.customer.email",
    "data.customer_email",
    "data.customerEmail",
    "data.buyer.email",
    "data.buyer_email",
    "data.buyerEmail",
  ]);

  const ownerName = findString(payload, [
    "name",
    "customer_name",
    "customerName",
    "buyer_name",
    "buyerName",
    "data.name",
    "data.customer.name",
    "data.customer_name",
    "data.customerName",
    "data.buyer.name",
    "data.buyer_name",
    "data.buyerName",
  ]);

  const licenseCode = findString(payload, [
    "license_code",
    "licenseCode",
    "metadata.license_code",
    "metadata.licenseCode",
    "data.license_code",
    "data.licenseCode",
    "data.metadata.license_code",
    "data.metadata.licenseCode",
  ]);

  return {
    eventId,
    eventType,
    transactionId,
    rawStatus,
    normalizedStatus: normalizeUpper(rawStatus),
    ownerEmail,
    ownerName,
    licenseCode,
  };
}

Deno.serve(async (req) => {
  const cors = handleCors(req);
  if (cors) return cors;

  if (req.method !== "POST") {
    return jsonResponse({
      ok: false,
      error: "Method not allowed",
    }, 405);
  }

  if (!(await authorizeWebhook(req))) {
    return jsonResponse({
      ok: false,
      error: "Unauthorized webhook",
    }, 401);
  }

  const supabase = createSupabaseAdminClient();

  let payload: Record<string, unknown>;

  try {
    payload = await parseJson(req);
  } catch (error) {
    return jsonResponse({
      ok: false,
      error: error instanceof Error ? error.message : "Invalid request body",
    }, 400);
  }

  const info = extractPayloadInfo(payload);

  const { data: existingEvent, error: existingEventError } = await supabase
    .from("mayar_webhook_events")
    .select("id, processing_status, license_id")
    .eq("event_id", info.eventId)
    .maybeSingle();

  if (existingEventError) {
    return jsonResponse({
      ok: false,
      error: "Failed to check webhook idempotency",
      detail: existingEventError.message,
    }, 500);
  }

  if (existingEvent?.processing_status === "PROCESSED") {
    return jsonResponse({
      ok: true,
      duplicate: true,
      licenseId: existingEvent.license_id,
    });
  }

  const { data: eventRow, error: eventError } = await supabase
    .from("mayar_webhook_events")
    .upsert({
      event_id: info.eventId,
      event_type: info.eventType,
      transaction_id: info.transactionId,
      processing_status: "RECEIVED",
      payload,
    }, {
      onConflict: "event_id",
    })
    .select("id")
    .single();

  if (eventError || !eventRow) {
    return jsonResponse({
      ok: false,
      error: "Failed to save webhook event",
      detail: eventError?.message ?? "Unknown webhook event insert error",
    }, 500);
  }

  if (!PAID_STATUSES.has(info.normalizedStatus)) {
    await supabase
      .from("mayar_webhook_events")
      .update({
        processing_status: "IGNORED",
        processed_at: new Date().toISOString(),
      })
      .eq("id", eventRow.id);

    return jsonResponse({
      ok: true,
      ignored: true,
      reason: "Webhook status is not paid/success",
      status: info.rawStatus,
    });
  }

  if (!info.ownerEmail) {
    await supabase
      .from("mayar_webhook_events")
      .update({
        processing_status: "FAILED",
        error_message: "Missing customer email in Mayar payload",
        processed_at: new Date().toISOString(),
      })
      .eq("id", eventRow.id);

    return jsonResponse({
      ok: false,
      error: "Missing customer email in Mayar payload",
    }, 422);
  }

  const licenseCode = info.licenseCode ?? createLicenseCode();
  const billingCycle = getBillingCycle(payload);
  const activeUntil = getActiveUntil(billingCycle);
  const now = new Date().toISOString();

  let existingLicense = null;

  if (info.transactionId) {
    const { data } = await supabase
      .from("licenses")
      .select("id, license_code")
      .eq("mayar_transaction_id", info.transactionId)
      .maybeSingle();

    existingLicense = data;
  }

  if (!existingLicense) {
    const { data } = await supabase
      .from("licenses")
      .select("id, license_code")
      .eq("license_code", licenseCode)
      .maybeSingle();

    existingLicense = data;
  }

  let finalLicense = null;

  if (existingLicense) {
    const { data, error } = await supabase
      .from("licenses")
      .update({
        owner_email: info.ownerEmail,
        owner_name: info.ownerName,
        status: "ACTIVE",
        billing_cycle: billingCycle,
        mayar_transaction_id: info.transactionId,
        active_from: now,
        active_until: activeUntil,
        metadata: {
          source: "mayar",
          last_webhook_event_id: info.eventId,
          last_webhook_event_type: info.eventType,
        },
      })
      .eq("id", existingLicense.id)
      .select("id, license_code")
      .single();

    if (error || !data) {
      await supabase
        .from("mayar_webhook_events")
        .update({
          processing_status: "FAILED",
          error_message: error?.message ?? "Unknown license update error",
          processed_at: now,
        })
        .eq("id", eventRow.id);

      return jsonResponse({
        ok: false,
        error: "Failed to update license",
        detail: error?.message ?? "Unknown license update error",
      }, 500);
    }

    finalLicense = data;
  } else {
    const { data, error } = await supabase
      .from("licenses")
      .insert({
        license_code: licenseCode,
        owner_email: info.ownerEmail,
        owner_name: info.ownerName,
        status: "ACTIVE",
        billing_cycle: billingCycle,
        mayar_transaction_id: info.transactionId,
        active_from: now,
        active_until: activeUntil,
        max_devices: 1,
        metadata: {
          source: "mayar",
          first_webhook_event_id: info.eventId,
          first_webhook_event_type: info.eventType,
        },
      })
      .select("id, license_code")
      .single();

    if (error || !data) {
      await supabase
        .from("mayar_webhook_events")
        .update({
          processing_status: "FAILED",
          error_message: error?.message ?? "Unknown license insert error",
          processed_at: now,
        })
        .eq("id", eventRow.id);

      return jsonResponse({
        ok: false,
        error: "Failed to create license",
        detail: error?.message ?? "Unknown license insert error",
      }, 500);
    }

    finalLicense = data;
  }

  await supabase
    .from("mayar_webhook_events")
    .update({
      license_id: finalLicense.id,
      processing_status: "PROCESSED",
      processed_at: new Date().toISOString(),
    })
    .eq("id", eventRow.id);

  return jsonResponse({
    ok: true,
    licenseId: finalLicense.id,
    licenseCode: finalLicense.license_code,
  });
});
