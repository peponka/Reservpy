-- ============================================================
-- ReservPy — CN-005: Reservas manuales sin hack clientId
-- 2026-06-07
--
-- Agrega columnas is_manual / manual_client_name / manual_client_phone
-- y hace client_id nullable para reservas cargadas por el dueño.
--
-- EJECUTAR en Supabase Dashboard > SQL Editor.
-- Es seguro de re-ejecutar (IF NOT EXISTS / DROP IF EXISTS).
-- ============================================================


-- 1. Nuevas columnas en reservations
ALTER TABLE public.reservations
  ADD COLUMN IF NOT EXISTS is_manual       BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS manual_client_name  TEXT,
  ADD COLUMN IF NOT EXISTS manual_client_phone TEXT;

-- 2. client_id pasa a ser nullable
--    (reservas manuales no tienen perfil registrado)
ALTER TABLE public.reservations
  ALTER COLUMN client_id DROP NOT NULL;


-- 3. Reemplazar política de INSERT por una que cubre ambos casos
DROP POLICY IF EXISTS "reservations_insert_client" ON public.reservations;
DROP POLICY IF EXISTS "reservations_insert_v2"     ON public.reservations;

-- Caso A: cliente real reserva para sí mismo
-- Caso B: dueño del negocio carga un turno manual
CREATE POLICY "reservations_insert_v2" ON public.reservations
  FOR INSERT
  WITH CHECK (
    (
      is_manual = false
      AND auth.uid() = client_id
    )
    OR
    (
      is_manual = true
      AND EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = business_id
          AND owner_id = auth.uid()
      )
    )
  );


-- 4. Verificación rápida (ejecutar aparte si querés confirmar)
-- SELECT id, is_manual, manual_client_name, manual_client_phone, client_id
-- FROM public.reservations
-- LIMIT 5;
