-- ReservPy: Setup WhatsApp reminders
-- Ejecutar en Supabase SQL Editor

-- 1. Columna para rastrear recordatorios
ALTER TABLE public.reservations
  ADD COLUMN IF NOT EXISTS whatsapp_reminder_sent BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_reservations_reminder
  ON public.reservations (status, whatsapp_reminder_sent, start_time)
  WHERE status IN ('pending', 'confirmed') AND whatsapp_reminder_sent = FALSE;

-- 2. Activar pg_cron: Dashboard â†’ Database â†’ Extensions â†’ pg_cron

-- 3. Programar cron cada hora (reemplazar <PROJECT_REF> y <SERVICE_ROLE_KEY>)
SELECT cron.schedule('whatsapp-reminders-hourly','0 * * * *',$$
  SELECT net.http_post(
    url := 'https://<PROH¤ƒECT_REF>.supabase.co/functions/v1/whatsapp-reminders',
    headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer <SERVICE_ROLE_KEY>'),
    body := '{}'::jsonb);
$$);

-- Variables en Supabase > Edge Functions > Manage secrets:
-- TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_WHATSAPP_FROM
--
-- Sandbox: cada usuario envia "join <keyword>" al +14155238886
