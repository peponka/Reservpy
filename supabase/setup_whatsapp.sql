-- ReservPy: Setup WhatsApp reminders
-- Ejecutar en Supabase SQL Editor

-- 1. Columna para rastrear si alguna reserva ya recibio al menos un recordatorio
ALTER TABLE public.reservations
  ADD COLUMN IF NOT EXISTS whatsapp_reminder_sent BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_reservations_reminder
  ON public.reservations (status, whatsapp_reminder_sent, start_time)
  WHERE status IN ('pending', 'confirmed') AND whatsapp_reminder_sent = FALSE;

-- 2. Tabla para deduplicar envios por horario configurado
CREATE TABLE IF NOT EXISTS public.reservation_reminder_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id UUID NOT NULL REFERENCES public.reservations(id) ON DELETE CASCADE,
  reminder_hours_before INT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (reservation_id, reminder_hours_before)
);

ALTER TABLE public.reservation_reminder_deliveries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Reservation reminder deliveries: read own" ON public.reservation_reminder_deliveries;
CREATE POLICY "Reservation reminder deliveries: read own" ON public.reservation_reminder_deliveries FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM public.reservations r
    JOIN public.businesses b ON b.id = r.business_id
    WHERE r.id = reservation_id AND (b.owner_id = auth.uid() OR r.client_id = auth.uid())
  )
);

CREATE INDEX IF NOT EXISTS idx_reservation_reminder_deliveries_reservation
  ON public.reservation_reminder_deliveries(reservation_id);

-- 3. Activar pg_cron: Dashboard > Database > Extensions > pg_cron
-- 4. Programar cron cada hora (reemplazar <PROJECT_REF> y <SERVICE_ROLE_KEY>)
SELECT cron.schedule('whatsapp-reminders-hourly','0 * * * *',$$
  SELECT net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/whatsapp-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <SERVICE_ROLE_KEY>'
    ),
    body := '{"source":"pg_cron"}'::jsonb
  );
$$);

-- 5. Para actualizar el cron sin duplicarlo
-- SELECT cron.unschedule('whatsapp-reminders-hourly');
