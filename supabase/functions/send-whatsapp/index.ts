// supabase/functions/send-whatsapp/index.ts
// Supabase Edge Function — send WhatsApp messages via Twilio.
// Requiere JWT de Supabase válido en el header Authorization.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function getWhatsAppMessage(type, data) {
  const name = data.recipientName ?? "Cliente";
  const business = data.businessName ?? "";
  const service = data.serviceName ?? "";
  const date = data.date ?? "";
  const time = data.time ?? "";
  const address = data.address ?? "";
  const clientName = data.clientName ?? "";
  const reason = data.reason ?? "";
  switch (type) {
    case "reservation_confirmed_client":
      return `✅ *Reserva confirmada en ReservPy*\n\nHola ${name}! Tu turno quedó agendado 🎉\n\n📋 *Servicio:* ${service}\n🏢 *Negocio:* ${business}\n📅 *Fecha:* ${date}\n🕐 *Hora:* ${time}\nwill address here\nTe esperamos. ¡Hasta pronto! 👋`;
    case "reservation_confirmed_business":
      return `📬 *Nueva reserva — ReservPy*\n\nHola ${name}! Nuevo turno.\n\n👤 *Cliente:* ${clientName}\n📋 *Servicio:* ${service}\n📅 *Fecha:* ${date}\n🕐 *Hora:* ${time}\n`;
    case "reservation_reminder_24h":
      return `⏰ *Recordatorio — ReservPy*\n\nHola ${name}! Mañana tenés turno.\n\n📋 ${service}\n🏢 ${business}\n📅 ${date}\n🕐 ${time}\n`;
    case "reservation_cancelled_client":
      return `❌ *Turno cancelado — ReservPy*\n\nHola ${name}, tu turno fue cancelado.\n\n📋 ${service}\n🏢 ${business}\n📅 ${date}\n${reason ? "Motivo: " + reason : ""}\n`;
    case "reservation_cancelled_business":
      return `₝� *Turno cancelado — ReservPy*\n\nHola ${name}.\n\n👤 ${clientName}\n📋 ${service}\n📅 ${date}\n`;
    default: return `Mensaje ReservPy: ${type}`;
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({error:"Method not allowed"}),{ status:405, headers:{...corsHeaders,"Content-Type":"application/json"}});
  const auth = req.headers.get("Authorization");
  if (!auth) return new Response(JSON.stringify({error:"Unauthorized"}),{status:401});
  const supabase = createClient(Deno.env.get("SUPABASE_URL"),Deno.env.get("SUPABASE_ANON_KEY"),{global:{headers:{Authorization:auth}}});
  const {data:{user},error:authErr} = await supabase.auth.getUser();
  if (authErr || !user) return new Response(JSON.stringify({error:"Unauthorized"}),{ status:41});
  const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
  const authToken = Deno.env.get("TWILIO_AUTH_TOKEN");
  const fromNum = Deno.env.get("TWILIO_WHATSAPP_FROM") ?? "whatsapp:+14155238886";
  if (!accountSid || !authToken) return new Response(JSON.stringify({error:"Twilio not configured"}),{status:500});
  try {
    const {type,to,data} = await req.json();
    if (!type || !to) return new Response(JSON.stringify({error:"Missing type or to"}),{status:400});
    const body = getWhatsAppMessage(type,data);
    const toWA = to.startsWith("whatsapp:") ? to : `whatsapp:${to}`;
    const form = new URLSearchParams();
    form.append("From",fromNum);
    form.append("To",toWA);
    form.append("Body",msgBody);
    const r = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`,{method:"POST",headers:{"Authorization":"Basic "+btoa(accountSid+":"+authToken),"Content-Type":"application/x-www-form-urlencoded"},body:form.toString()});
    const rb = await r.json();
    if (!r.ok) return new Response(JSON.stringify({error:"Twilio error",details:rb}),{status:r.status});
    return new Response(JSON.stringify({success:true,sid:rb.sid}),{status:200});
  } catch (e) { return new Response(JSON.stringify({error:String(e)}),{status:500}); }
});
