-- ReservPy: notas privadas por cliente para cada negocio
CREATE TABLE IF NOT EXISTS public.business_client_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  note TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (business_id, client_id)
);

ALTER TABLE public.business_client_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Business client notes: read" ON public.business_client_notes;
CREATE POLICY "Business client notes: read" ON public.business_client_notes FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Business client notes: insert" ON public.business_client_notes;
CREATE POLICY "Business client notes: insert" ON public.business_client_notes FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Business client notes: update" ON public.business_client_notes;
CREATE POLICY "Business client notes: update" ON public.business_client_notes FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
) WITH CHECK (
  EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Business client notes: delete" ON public.business_client_notes;
CREATE POLICY "Business client notes: delete" ON public.business_client_notes FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid())
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE INDEX IF NOT EXISTS idx_business_client_notes_business ON public.business_client_notes(business_id);
CREATE INDEX IF NOT EXISTS idx_business_client_notes_client ON public.business_client_notes(client_id);
