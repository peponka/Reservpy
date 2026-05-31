// supabase/functions/send-email/index.ts
// Supabase Edge Function — send transactional emails via Resend.

import { getEmailTemplate } from "./templates.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request): Promise<Response> => {
  // ── CORS preflight ──────────────────────────────────────────────────
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // ── Only allow POST ─────────────────────────────────────────────────
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  try {
    // ── Parse request body ────────────────────────────────────────────
    const { type, to, data } = (await req.json()) as {
      type: string;
      to: string | string[];
      data: Record<string, unknown>;
    };

    if (!type || !to) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: type, to" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── Render template ───────────────────────────────────────────────
    const { subject, html } = getEmailTemplate(type, data ?? {});

    // ── Send via Resend ───────────────────────────────────────────────
    const apiKey = Deno.env.get("RESEND_API_KEY");
    if (!apiKey) {
      throw new Error("RESEND_API_KEY is not set");
    }

    const from =
      Deno.env.get("FROM_EMAIL") ?? "ReservPy <no-reply@reservpy.com>";

    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({ from, to, subject, html }),
    });

    const resendBody = await resendRes.json();

    if (!resendRes.ok) {
      console.error("Resend API error:", JSON.stringify(resendBody));
      return new Response(
        JSON.stringify({ error: "Failed to send email", details: resendBody }),
        {
          status: resendRes.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // ── Success ───────────────────────────────────────────────────────
    return new Response(
      JSON.stringify({ success: true, id: resendBody.id }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : "Internal server error";
    console.error("send-email error:", message);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
