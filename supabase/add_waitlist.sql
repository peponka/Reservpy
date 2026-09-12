-- ReservPy - Lista de espera con relleno automatico de cancelaciones (12/9/2026)
--
-- Flujo: un cliente se anota para un negocio + fecha (opcionalmente un
-- servicio). Cuando se cancela un turno de ese negocio ese mismo dia
-- (ReservationRepository.updateStatus -> WaitlistRepository.tryFillFromCancellation),
-- se le avisa por WhatsApp al primero en la lista que ese horario quedo
-- libre, con una ventana de tiempo para confirmar. Si no confirma a tiempo,
-- pasa al siguiente (WaitlistRepository.expireStaleNotifications).

CREATE TABLE IF NOT EXISTS public.waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  preferred_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'notified', 'booked', 'expired', 'cancelled')),
  -- Horario concreto que se le ofrecio (se llena solo cuando status = 'notified'/'booked')
  notified_start_time TIMESTAMPTZ,
  notified_end_time TIMESTAMPTZ,
  notify_expires_at TIMESTAMPTZ,
  reservation_id UUID REFERENCES public.reservations(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Waitlist: read own or business" ON public.waitlist
  FOR SELECT USING (
    client_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  );

CREATE POLICY "Waitlist: client insert" ON public.waitlist
  FOR INSERT TO authenticated WITH CHECK (client_id = auth.uid());

CREATE POLICY "Waitlist: update own or business" ON public.waitlist
  FOR UPDATE USING (
    client_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  );

CREATE POLICY "Waitlist: delete own or business" ON public.waitlist
  FOR DELETE USING (
    client_id = auth.uid()
    OR EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  );

-- Solo puede haber una fila 'waiting' por cliente+negocio+fecha+servicio
-- (evita anotarse duplicado al mismo dia sin querer).
CREATE UNIQUE INDEX IF NOT EXISTS idx_waitlist_unique_waiting
  ON public.waitlist(business_id, client_id, preferred_date, COALESCE(service_id, '00000000-0000-0000-0000-000000000000'))
  WHERE status = 'waiting';

CREATE INDEX IF NOT EXISTS idx_waitlist_business_date_waiting
  ON public.waitlist(business_id, preferred_date) WHERE status = 'waiting';
CREATE INDEX IF NOT EXISTS idx_waitlist_business_notified
  ON public.waitlist(business_id, notify_expires_at) WHERE status = 'notified';
CREATE INDEX IF NOT EXISTS idx_waitlist_client ON public.waitlist(client_id);
