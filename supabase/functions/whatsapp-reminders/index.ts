// supabase/functions/whatsapp-reminders/index.ts
// Cron Edge Function — envía recordatorios de WhatsApp 24hs antes del turno.
// Schedule: "0 * * * *" (cada hora)
// Requiere: ALTER TAABLE whatsapp_reminder_sent BOOLEAN DEFAULT FALSE;

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function normalizePhone(raw) {
  const d = raw.replace(/[^\d]/g,"");
  if (d.startsWith("595")&&d.length===12) return `+${d}`;
  if (d.startsWith("0")&&d.length===10) return `+595${d.substring(1)}`;
  if (d.length===9) return `+595${d}`;
  if (raw.startsWith("+")) return raw;
  return null;
}

Deno.serve(async () => {
  const supabase = createClient(Deno.env.get("SUPABASE_URL"),Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
  const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
  const authToken = Deno.env.get("TWILIO_AUTH_TOKEN");
  const fromNum = Deno.env.get("TWILIO_WHATSAPP_FROM") ?? "whatsapp:+14155238886";
  if (!accountSid || !authToken) return new Response(JSON.stringify({error:"Missing Twilio credentials"}),{status:500});
  const now = new Date();
  const wStart = new Date(now.getTime()+23*3600000);
  const wEnd = new Date(now.getTime()+25*3600000);
  const {data:reservations,error} = await supabase.from("reservations")
    .select("id,start_time,service_name,business_name,businesses(address),profiles:client_id(first_name,last_name,phone)")
    .in("status",["pending","confirmed"])
    .eq("whatsapp_reminder_sent",false)
    .gte("start_time",wStart.toISOString())
    .lte("start_time",wEnd.toISOString());
  if (error) return new Response(JSON.stringify({error:error.message}),{status:500});
  if (!reservations?.length) return new Response(JSON.stringify({sent:0}),{status:200});
  const creds = btoa(`${accountSid}:${authToken}`);
  const twUrl = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;
  let sent=0;
  for (const res of reservations) {
    const phone = res.profiles?.phone;
    if (!phone) continue;
    const norm = normalizePhone(phone);
    if (!norm) continue;
    const t = new Date(res.start_time);
    const name = `${res.profiles?.first_name??""} ${res.profiles?.last_name??""}`.trim();
    const msg = `⏰ *Recordatorio — ReservPy*\n\nHola ${name|"|Cliente"}! Mañana tenés turno.\n\n📋 ${res.service_name}\n🏢 ${res.business_name}\n📅 ${String(t.getDate()).padStart(2,"0")}/${String(t.getMonth()+1).padStart(2,"0")}/${t.getFullYear()}\n🕐 ${String(t.getHours()).padStart(2,"0")}:${String(t.getMinutes()).padStart(2,"0")}\n📍 ${res.businesses?.address??""}\n\n¡Te esperamos! 😊`;
    const form = new URLSearchParams();
    form.append("From",fromNum);
    form.append("To",`whatsapp:${norm}`);
    form.append("Body",msg);
    try {
      const r = await fetch(twUrl,{method:"POST",headers:{"Authorization":"Basic "+creds,"Content-Type":"application/x-www-form-urlencoded"},body:form.toString()});
      if (r.ok) {
        await supabase.from("reservations").update({whatsapp_reminder_sent:true}).eq("id",res.id);
        sent++;
      }
    } catch(e) { console.error(`Reminder error ${res.id}:`,e); }
  }
  return new Response(JSON.stringify({sent}),{status:200});
});
