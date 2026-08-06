// supabase/functions/whatsapp-reminders/index.ts
// Cron Edge Function — envía recordatorios de WhatsApp 24hs antes del turno.
// Schedule sugerido: "0 * * * *" (cada hora)
//
// Usa la Cloud API de Meta directamente (sin Twilio de por medio).
//
// Requiere estos secrets en Supabase (Edge Functions → Secrets):
//   WHATSAPP_PHONE_NUMBER_ID  -> id del numero remitente (Meta lo da en API Setup)
//   WHATSAPP_ACCESS_TOKEN     -> token permanente (System User), NO el de 24hs
// Opcionales (tienen default):
//   WHATSAPP_API_VERSION      -> default v25.0
//   WHATSAPP_TEMPLATE_NAME    -> default recordatorio_turno
//   WHATSAPP_TEMPLATE_LANG    -> default es_AR
//
// POR QUE PLANTILLA Y NO TEXTO LIBRE: WhatsApp solo permite texto libre dentro
// de las 24hs desde el ultimo mensaje del cliente. Un recordatorio lo inicia el
// negocio y cae fuera de esa ventana, asi que con texto libre Meta lo acepta y
// despues NO lo entrega, en silencio. Por eso va como template.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TZ = "America/Asuncion";

/** Numero paraguayo -> E.164 sin el "+" (formato que espera la Cloud API). */
function normalizePhone(raw: string): string | null {
  const d = String(raw ?? "").replace(/[^\d]/g, "");
  if (!d) return null;
  if (d.startsWith("595") && d.length === 12) return d;        // 595 + 9 digitos
  if (d.startsWith("0") && d.length === 10) return `595${d.slice(1)}`; // 0994xxxxxx
  if (d.length === 9) return `595${d}`;                        // 994xxxxxx
  return null;
}

// OJO: sin timeZone, Deno formatea en UTC y el recordatorio saldria con 3hs de
// diferencia (un turno de las 15:30 se anunciaria como 18:30).
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

  // Ventana 23-25hs: el cron corre cada hora, asi que cada turno cae en la
  // ventana una sola vez. whatsapp_reminder_sent evita repetirlo igual.
  const now = Date.now();
  const wStart = new Date(now + 23 * 3600_000).toISOString();
  const wEnd = new Date(now + 25 * 3600_000).toISOString();

  // OJO: reservations NO tiene columnas service_name/business_name (el codigo
  // viejo las pedia y por eso fallaba con "column does not exist"). Los nombres
  // salen de las tablas relacionadas via service_id / business_id.
  const { data: reservations, error } = await supabase
    .from("reservations")
    .select(
      "id,start_time,is_manual,manual_client_name,manual_client_phone," +
        "services(name),businesses(name)," +
        "profiles:client_id(first_name,last_name,phone)",
    )
    .in("status", ["pending", "confirmed"])
    .eq("whatsapp_reminder_sent", false)
    .gte("start_time", wStart)
    .lte("start_time", wEnd);

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

  const url = `https://graph.facebook.com/${apiVersion}/${phoneNumberId}/messages`;
  let sent = 0, skipped = 0, failed = 0;
  const errores: unknown[] = [];

  // PostgREST devuelve la relacion como objeto, pero segun como infiera la
  // cardinalidad puede venir como array de uno. Aceptamos las dos formas.
  const uno = <T,>(rel: unknown): T | null =>
    Array.isArray(rel) ? ((rel[0] ?? null) as T | null) : ((rel ?? null) as T | null);

  for (const res of reservations) {
    const perfil = uno<{ first_name?: string; last_name?: string; phone?: string }>(res.profiles);
    const servicio = uno<{ name?: string }>(res.services);
    const negocio = uno<{ name?: string }>(res.businesses);

    // Las reservas cargadas a mano por el negocio (turnos por telefono) no
    // tienen profile: el nombre y el telefono del cliente van en la propia fila.
    // Sin esto, esos clientes nunca recibirian el recordatorio.
    const telefonoCrudo = res.is_manual
      ? (res.manual_client_phone as string | null) ?? perfil?.phone
      : perfil?.phone ?? (res.manual_client_phone as string | null);

    const to = normalizePhone(telefonoCrudo ?? "");
    if (!to) { skipped++; continue; }

    const nombrePerfil = `${perfil?.first_name ?? ""} ${perfil?.last_name ?? ""}`.trim();
    const nombre =
      (res.is_manual ? (res.manual_client_name as string | null) : null) ||
      nombrePerfil ||
      (res.manual_client_name as string | null) ||
      "Cliente";

    const inicio = new Date(res.start_time as string);

    // El orden de los parametros TIENE que coincidir con la plantilla aprobada:
    // {{1}} cliente, {{2}} negocio, {{3}} servicio, {{4}} fecha, {{5}} hora.
    const parameters = [
      nombre,
      negocio?.name ?? "el negocio",
      servicio?.name ?? "tu servicio",
      fechaPy(inicio),
      horaPy(inicio),
    ].map((text) => ({ type: "text", text }));

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

      // Solo marcamos como enviado si Meta devolvio un id de mensaje. El codigo
      // viejo marcaba con que el POST diera OK, asi que daba por "enviados"
      // recordatorios que nadie recibia.
      const messageId = body?.messages?.[0]?.id;
      if (r.ok && messageId) {
        await supabase
          .from("reservations")
          .update({ whatsapp_reminder_sent: true })
          .eq("id", res.id);
        sent++;
      } else {
        failed++;
        errores.push({ id: res.id, status: r.status, body });
        console.error(`Recordatorio ${res.id} rechazado por Meta:`, JSON.stringify(body));
      }
    } catch (e) {
      failed++;
      errores.push({ id: res.id, error: String(e) });
      console.error(`Recordatorio ${res.id} fallo:`, e);
    }
  }

  return new Response(
    JSON.stringify({ sent, skipped, failed, errores: errores.slice(0, 5) }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});
