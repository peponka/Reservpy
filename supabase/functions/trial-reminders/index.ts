// supabase/functions/trial-reminders/index.ts
// Daily job: emails businesses whose free trial ends in ~7 days, and flips
// expired trials to subscription_status = 'expired'.
// Activated via pg_cron — see supabase_trial_system.sql for the schedule.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
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

function buildReminderEmail(
  ownerName: string,
  businessName: string,
  daysLeft: number,
  trialEndDate: string,
): string {
  const PRIMARY = "#00C896";
  const DARK = "#1A1A2E";
  const LIGHT_BG = "#F4F6F8";
  const FONT = "'Inter', 'Segoe UI', Arial, sans-serif";

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
          <h1 style="margin:0 0 8px;font-size:20px;font-weight:700;">Tu mes gratis está por terminar ⏳</h1>
          <p style="margin:0 0 20px;font-size:14px;color:#555555;line-height:1.6;">
            Hola, <strong>${ownerName}</strong>. El período de prueba gratuito de
            <strong style="color:${PRIMARY};">${businessName}</strong> vence en
            <strong>${daysLeft} día${daysLeft === 1 ? "" : "s"}</strong> (${trialEndDate}).
          </p>
          <p style="margin:0 0 24px;font-size:14px;color:#555555;line-height:1.6;">
            Para que tu negocio siga recibiendo reservas online sin interrupciones,
            activá el plan Pro antes de esa fecha.
          </p>
          <table cellpadding="0" cellspacing="0" style="margin:0 auto;">
            <tr><td style="background:${PRIMARY};border-radius:8px;text-align:center;">
              <a href="https://www.reservpy.com/upgrade" style="display:inline-block;padding:12px 28px;color:#fff;font-size:15px;font-weight:600;text-decoration:none;">
                Activar plan Pro
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

  const resendKey = Deno.env.get("RESEND_API_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  if (!resendKey) return json({ error: "RESEND_API_KEY not set" }, 500);

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const now = new Date();
  const in7Days = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
  const fmt = (d: string) =>
    new Date(d).toLocaleDateString("es-PY", { day: "2-digit", month: "2-digit", year: "numeric" });

  // ── 1. Trials ending within the next 7 days — send a one-time reminder ──
  const { data: expiringSoon, error: expiringErr } = await admin
    .from("businesses")
    .select("id, name, owner_id, trial_ends_at")
    .eq("subscription_status", "trial")
    .eq("trial_reminder_sent", false)
    .lte("trial_ends_at", in7Days.toISOString())
    .gt("trial_ends_at", now.toISOString());

  let remindersSent = 0;
  if (!expiringErr && expiringSoon?.length) {
    for (const biz of expiringSoon) {
      const { data: userData } = await admin.auth.admin.getUserById(biz.owner_id);
      const ownerEmail = userData?.user?.email;
      if (!ownerEmail) continue;

      const { data: profile } = await admin
        .from("profiles")
        .select("first_name")
        .eq("id", biz.owner_id)
        .maybeSingle();
      const ownerName = profile?.first_name ?? "dueño";

      const daysLeft = Math.max(
        1,
        Math.ceil((new Date(biz.trial_ends_at).getTime() - now.getTime()) / (24 * 60 * 60 * 1000)),
      );

      await sendEmail(
        resendKey,
        ownerEmail,
        `Tu mes gratis en ReservPy vence en ${daysLeft} día${daysLeft === 1 ? "" : "s"}`,
        buildReminderEmail(ownerName, biz.name, daysLeft, fmt(biz.trial_ends_at)),
      );

      await admin
        .from("businesses")
        .update({ trial_reminder_sent: true })
        .eq("id", biz.id);

      remindersSent++;
    }
  }

  // ── 2. Trials that already expired — flip status, no more Pro-level access ──
  const { data: expired, error: expireErr } = await admin
    .from("businesses")
    .update({ subscription_status: "expired" })
    .eq("subscription_status", "trial")
    .lt("trial_ends_at", now.toISOString())
    .select("id");

  return json({
    ok: true,
    remindersSent,
    expiredCount: expireErr ? 0 : (expired?.length ?? 0),
  });
});
