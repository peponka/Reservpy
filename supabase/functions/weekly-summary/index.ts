// supabase/functions/weekly-summary/index.ts
// Envía un resumen semanal con IA a cada dueño de negocio activo.
// Se activa via pg_cron (Supabase Dashboard → SQL Editor):
//
//   select cron.schedule(
//     'weekly-summary-lunes',
//     '0 12 * * 1',   -- 12:00 UTC (09:00 Asunción) cada lunes
//     $$
//     select net.http_post(
//       url := 'https://cmntfqsruljhlgqirtkw.supabase.co/functions/v1/weekly-summary',
//       headers := jsonb_build_object(
//         'Content-Type', 'application/json',
//         'Authorization', 'Bearer <SERVICE_ROLE_KEY>'
//       ),
//       body := '{}'::jsonb
//     );
//     $$
//   );

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const GEMINI_MODELS = ["gemini-2.0-flash", "gemini-2.5-flash-lite"];
const geminiUrl = (m: string) =>
  `https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent`;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function geminiText(
  apiKey: string,
  prompt: string,
  maxTokens = 250,
): Promise<string> {
  for (const model of GEMINI_MODELS) {
    const res = await fetch(`${geminiUrl(model)}?key=${apiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: maxTokens, temperature: 0.65 },
      }),
    });
    if (res.status === 429 || res.status === 503) continue;
    if (!res.ok) break;
    const d = await res.json();
    return (d.candidates?.[0]?.content?.parts?.[0]?.text ?? "").trim();
  }
  return "";
}

async function sendEmail(
  resendKey: string,
  to: string,
  subject: string,
  html: string,
): Promise<void> {
  const from = Deno.env.get("FROM_EMAIL") ?? "ReservPy <no-reply@reservpy.com>";
  await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${resendKey}`,
    },
    body: JSON.stringify({ from, to, subject, html }),
  });
}

function buildSummaryEmail(
  ownerName: string,
  businessName: string,
  weekRange: string,
  total: number,
  completed: number,
  cancelled: number,
  diffPct: number | null,
  aiSummary: string,
): string {
  const PRIMARY = "#00C896";
  const DARK = "#1A1A2E";
  const LIGHT_BG = "#F4F6F8";
  const FONT = "'Inter', 'Segoe UI', Arial, sans-serif";

  const trend = diffPct === null
    ? ""
    : diffPct > 0
    ? `<span style="color:${PRIMARY};font-weight:600;">↑ ${diffPct}%</span> vs semana anterior`
    : diffPct < 0
    ? `<span style="color:#EF4444;font-weight:600;">↓ ${Math.abs(diffPct)}%</span> vs semana anterior`
    : `igual que la semana anterior`;

  const statCard = (label: string, value: string, color: string) =>
    `<td style="width:33%;padding:0 6px;text-align:center;">
      <div style="background:#fff;border-radius:10px;padding:14px 8px;border:1px solid #E5E7EB;">
        <div style="font-size:22px;font-weight:700;color:${color};">${value}</div>
        <div style="font-size:11px;color:#6B7280;margin-top:4px;text-transform:uppercase;letter-spacing:0.5px;">${label}</div>
      </div>
    </td>`;

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/></head>
<body style="margin:0;padding:0;background:${LIGHT_BG};font-family:${FONT};color:${DARK};">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:${LIGHT_BG};">
    <tr><td style="padding:32px 16px;">
      <table align="center" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;margin:0 auto;">
        <tr><td style="text-align:center;padding-bottom:20px;">
          <span style="font-size:26px;font-weight:700;color:${PRIMARY};">ReservPy</span>
        </td></tr>
        <tr><td style="background:#fff;border-radius:12px;padding:32px;box-shadow:0 2px 8px rgba(0,0,0,0.06);">
          <h1 style="margin:0 0 6px;font-size:20px;font-weight:700;">Resumen semanal 📊</h1>
          <p style="margin:0 0 4px;font-size:14px;color:#6B7280;">Hola, <strong>${ownerName}</strong> · ${businessName}</p>
          <p style="margin:0 0 24px;font-size:12px;color:#9CA3AF;">${weekRange}</p>

          <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:20px;">
            <tr>
              ${statCard("Turnos", String(total), PRIMARY)}
              ${statCard("Completados", String(completed), "#3B82F6")}
              ${statCard("Cancelados", String(cancelled), "#F59E0B")}
            </tr>
          </table>

          ${trend ? `<p style="font-size:13px;color:#6B7280;text-align:center;margin:0 0 20px;">${trend}</p>` : ""}

          <div style="background:${LIGHT_BG};border-radius:10px;padding:16px 20px;margin-bottom:24px;border-left:3px solid ${PRIMARY};">
            <p style="margin:0;font-size:14px;color:${DARK};line-height:1.6;">${aiSummary}</p>
          </div>

          <table cellpadding="0" cellspacing="0" style="margin:0 auto;">
            <tr><td style="background:${PRIMARY};border-radius:8px;text-align:center;">
              <a href="https://www.reservpy.com" style="display:inline-block;padding:11px 28px;color:#fff;font-size:14px;font-weight:600;text-decoration:none;">
                Ver mi panel
              </a>
            </td></tr>
          </table>
        </td></tr>
        <tr><td style="text-align:center;padding-top:20px;font-size:11px;color:#9CA3AF;line-height:1.6;">
          © 2026 ReservPy · Este email fue generado automáticamente.
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const geminiKey = Deno.env.get("GEMINI_API_KEY");
  const resendKey = Deno.env.get("RESEND_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  if (!resendKey) return json({ error: "RESEND_API_KEY not set" }, 500);

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Rango: últimos 7 días
  const now = new Date();
  const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const prevWeekAgo = new Date(weekAgo.getTime() - 7 * 24 * 60 * 60 * 1000);

  const fmt = (d: Date) =>
    d.toLocaleDateString("es-PY", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
  const weekRange = `${fmt(weekAgo)} – ${fmt(now)}`;

  // Obtener todos los negocios con su owner
  const { data: businesses, error: bizErr } = await admin
    .from("businesses")
    .select("id, name, owner_id");

  if (bizErr || !businesses?.length) {
    return json({ ok: true, processed: 0, note: "no businesses" });
  }

  let processed = 0;

  for (const biz of businesses) {
    // Email del owner
    const { data: userData } = await admin.auth.admin.getUserById(biz.owner_id);
    const ownerEmail = userData?.user?.email;
    if (!ownerEmail) continue;

    // Nombre del owner
    const { data: profile } = await admin
      .from("profiles")
      .select("first_name")
      .eq("id", biz.owner_id)
      .maybeSingle();
    const ownerName = profile?.first_name ?? "dueño";

    // Stats esta semana
    const { data: thisWeek } = await admin
      .from("reservations")
      .select("id, status")
      .eq("business_id", biz.id)
      .gte("start_time", weekAgo.toISOString())
      .lt("start_time", now.toISOString());

    const total = thisWeek?.length ?? 0;
    if (total === 0) continue; // no enviar si no hubo actividad

    const completed = thisWeek?.filter((r) => r.status === "completed").length ?? 0;
    const cancelled = thisWeek?.filter((r) => r.status === "cancelled").length ?? 0;

    // Stats semana anterior para comparación
    const { data: prevWeek } = await admin
      .from("reservations")
      .select("id")
      .eq("business_id", biz.id)
      .gte("start_time", prevWeekAgo.toISOString())
      .lt("start_time", weekAgo.toISOString());

    const prevTotal = prevWeek?.length ?? 0;
    const diffPct = prevTotal > 0
      ? Math.round(((total - prevTotal) / prevTotal) * 100)
      : null;

    // Generar resumen con Gemini
    let aiSummary = "";
    if (geminiKey) {
      const prompt =
        `Sos asistente de ReservPy, app de reservas en Paraguay.
Generá un resumen semanal breve y amigable para ${ownerName}, dueño de "${biz.name}".
Datos de la semana:
- Total de turnos: ${total}${diffPct !== null ? ` (${diffPct > 0 ? "+" : ""}${diffPct}% vs semana anterior)` : ""}
- Completados: ${completed}
- Cancelados: ${cancelled}
Escribí 2-3 oraciones en español rioplatense. Sé positivo pero honesto. Terminá con un tip accionable corto. Sin emojis.`;

      aiSummary = await geminiText(geminiKey, prompt);
    }

    if (!aiSummary) {
      aiSummary =
        `Esta semana tuviste ${total} turno${total !== 1 ? "s" : ""} — ${completed} completado${completed !== 1 ? "s" : ""} y ${cancelled} cancelado${cancelled !== 1 ? "s" : ""}. ` +
        (cancelled > completed
          ? "Considerá enviar recordatorios antes del turno para reducir cancelaciones."
          : "¡Buen ritmo, seguí así!");
    }

    const html = buildSummaryEmail(
      ownerName,
      biz.name,
      weekRange,
      total,
      completed,
      cancelled,
      diffPct,
      aiSummary,
    );

    await sendEmail(
      resendKey,
      ownerEmail,
      `Tu semana en ReservPy — ${biz.name} (${fmt(weekAgo)} al ${fmt(now)})`,
      html,
    );

    processed++;
  }

  return json({ ok: true, processed });
});
