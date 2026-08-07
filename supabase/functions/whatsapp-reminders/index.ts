// supabase/functions/whatsapp-reminders/index.ts
// Cron Edge Function — envía recordatorios de WhatsApp según la configuración
// guardada en cada negocio. Schedule sugerido: "0 * * * *" (cada hora).
//
// Usa la Cloud API de Meta directamente.
//
// Requiere estos secrets en Supabase (Edge Functions → Secrets):
//   WHATSAPP_PHONE_NUMBER_ID
//   WHATSAPP_ACCESS_TOKEN
// Opcionales:
//   WHATSAPP_API_VERSION  -> default v25.0
//   WHATSAPP_TEMPLATE_NAME -> default recordatorio_turno
//   WHATSAPP_TEMPLATE_LANG -> default es_AR

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TZ = "America/Asuncion";
const MAX_CONFIGURED_REMINDER_HOURS = 48;

function normalizePhone(raw: string): string | null {
  const d = String(raw ?? "").replace(/[^\d]/g, "");
  if (!d) return null;
  if (d.startsWith("595") && d.length === 12) return d;
  if (d.startsWith("0") && d.length === 10) return `595${d.slice(1)}`;
  if (d.length === 9) return `595${d}`;
  return null;
}

function fechaPy(d: Date): string {
  return new Intl.DateTimeFormat("es-PY", {
    timeZone: TZ, day: "2-digit", month: "2-digit", year: "numeric",
  }).format(d);
}

function horaPy(d: Date): string {
  return new Intl.DateTimeFormat("es-PY", {
    timeZone: TZ, hour: "2-digit", minute: "2-digit", hour12: false,
  }).format(d);
}

const uno = <T,>(rel: unknown): T | null =>
  Array.isArray(rel) ? ((rel[0] ?? null) as T | null) : ((rel ?? null) as T | null);

Deno.serve(async () => {
  const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
  const accessToken = Deno.env.get("WHATSAPP_ACCESS_TOKEN");
  const apiVersion = Deno.env.get("WHATSAPP_API_VERSION") ?? "v25.0";
  const templateName = Deno.env.get("WHATSAPP_TEMPLATE_NAME") ?? "recordatorio_turno";
  const templateLang = Deno.env.get("WHATSAPP_TEMPLATE_LANG") ?? "es_AR";

  if (!phoneNumberId || !accessToken) {
    return new Response(
      JSON.stringify({ error: "Faltan WHATSAPP_PHONE_NUMBER_ID y/o WHATSAPP_ACCESS_TOKEN" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const now = new Date();
  const windowStart = new Date(now.getTime() + 60 * 60_000).toISOString();
  const windowEnd = new Date(now.getTime() + (MAX_CONFIGURED_REMINDER_HOURS + 1) * 60 * 60_000).toISOString();

  const { data: reservations, error } = await supabase
    .from("reservations")
    .select(
      "id,start_time,is_manual,manual_client_name,manual_client_phone," +
        "services(name)," +
        "businesses(name,reminders_enabled,reminder_hours_before)," +
        "profiles:client_id(first_name,last_name,phone)",
    )
    .in("status", ["pending", "confirmed"])
    .gte("start_time", windowStart)
    .lte("start_time", windowEnd);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
  if (!reservations?.length) {
    return new Response(JSON.stringify({ sent: 0, skipped: 0, failed: 0 }), {
      status: 200, headers: { "Content-Type": "application/json" },
    });
  }

  const reservationIds = reservations.map((r) => r.id as string);
  const { data: deliveredRows } = await supabase
    .from("reservation_reminder_deliveries")
    .select("reservation_id, reminder_hours_before")
    .in("reservation_id", reservationIds);

  const delivered = new Set(
    (deliveredRows ?? []).map((row: { reservation_id: string; reminder_hours_before: number }) =>
      `${row.reservation_id}:${row.reminder_hours_before}`,
    ),
  );

  const url = `https://graph.facebook.com/${apiVersion}/${phoneNumberId}/messages`;
  let sent = 0;
  let skipped = 0;
  let failed = 0;
  const errores: unknown[] = [];

  for (const res of reservations) {
    const perfil = uno<{ first_name?: string; last_name?: string; phone?: string }>(res.profiles);
    const servicio = uno<{ name?: string }>(res.services);
    const negocio = uno<{ name?: string; reminders_enabled?: boolean; reminder_hours_before?: number[] }>(res.businesses);

    if (!negocio?.reminders_enabled) {
      skipped++;
      continue;
    }

    const configuredHours = Array.from(new Set((negocio.reminder_hours_before ?? [24])
      .filter((value) => Number.isFinite(value) && value > 0)))
      .sort((a, b) => a - b);

    const telefonoCrudo = res.is_manual
      ? (res.manual_client_phone as string | null) ?? perfil?.phone
      : perfil?.phone ?? (res.manual_client_phone as string | null);
    const to = normalizePhone(telefonoCrudo ?? "");
    if (!to) {
      skipped++;
      continue;
    }

    const nombrePerfil = `${perfil?.first_name ?? ""} ${perfil?.last_name ?? ""}`.trim();
    const nombre =
      (res.is_manual ? (res.manual_client_name as string | null) : null) ||
      nombrePerfil ||
      (res.manual_client_name as string | null) ||
      "Cliente";

    const inicio = new Date(res.start_time as string);
    const diffHours = (inicio.getTime() - now.getTime()) / 3600_000;
    const dueHours = configuredHours.filter((hours) => diffHours >= hours - 1 && diffHours <= hours + 1);

    if (!dueHours.length) {
      skipped++;
      continue;
    }

    const parameters = [
      nombre,
      negocio?.name ?? "el negocio",
      servicio?.name ?? "tu servicio",
      fechaPy(inicio),
      horaPy(inicio),
    ].map((text) => ({ type: "text", text }));

    for (const hours of dueHours) {
      const deliveryKey = `${res.id}:${hours}`;
      if (delivered.has(deliveryKey)) continue;

      try {
        const r = await fetch(url, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            messaging_product: "whatsapp",
            to,
            type: "template",
            template: {
              name: templateName,
              language: { code: templateLang },
              components: [{ type: "body", parameters }],
            },
          }),
        });

        const body = await r.json().catch(() => ({}));
        const messageId = body?.messages?.[0]?.id;

        if (r.ok && messageId) {
          await supabase.from("reservation_reminder_deliveries").insert({
            reservation_id: res.id,
            reminder_hours_before: hours,
            sent_at: new Date().toISOString(),
          });
          await supabase
            .from("reservations")
            .update({ whatsapp_reminder_sent: true })
            .eq("id", res.id);
          delivered.add(deliveryKey);
          sent++;
        } else {
          failed++;
          errores.push({ id: res.id, hours, status: r.status, body });
          console.error(`Recordatorio ${res.id} (${hours}h) rechazado por Meta:`, JSON.stringify(body));
        }
      } catch (e) {
        failed++;
        errores.push({ id: res.id, hours, error: String(e) });
        console.error(`Recordatorio ${res.id} (${hours}h) fallo:`, e);
      }
    }
  }

  return new Response(
    JSON.stringify({ sent, skipped, failed, errores: errores.slice(0, 5) }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
