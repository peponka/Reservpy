-- ReservPy: soporte para recordatorios en multiples horarios
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
