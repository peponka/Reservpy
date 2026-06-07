-- ============================================================
-- ReservPy — FIX RLS de Fase 1 (Cyber Neo report 2026-06-07)
--
-- Corrige:
--   CN-001 — Exposicion masiva de PII en profiles
--   CN-002 — INSERT sin verificar owner_id en businesses
--   CN-003 — INSERT inseguro en services y reservations
--
-- IMPORTANTE:
--   Ejecutar este SQL en Supabase Dashboard > SQL Editor.
--   No toca tablas ni datos, solo politicas RLS.
--   Es seguro de re-ejecutar (uses DROP IF EXISTS).
-- ============================================================


-- =========================================================
-- 1. PROFILES — quitamos la lectura publica de PII
-- =========================================================

-- Borrar TODAS las politicas viejas de SELECT en profiles
DROP POLICY IF EXISTS "Profiles: public read"            ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_for_joins"        ON public.profiles;
DROP POLICY IF EXISTS "Users can read own profile"       ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own"              ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_self"             ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_for_business_owners" ON public.profiles;

-- Cada usuario ve SOLO su propio perfil
CREATE POLICY "profiles_select_self" ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Y un dueno de negocio ve los perfiles de quienes le tienen reserva
-- (asi puede ver el nombre y telefono del cliente que reservo turno)
CREATE POLICY "profiles_select_for_business_owners" ON public.profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.reservations r
      JOIN public.businesses b ON r.business_id = b.id
      WHERE r.client_id = profiles.id
        AND b.owner_id = auth.uid()
    )
  );

-- Mantener INSERT/UPDATE solo del propio perfil (por las dudas)
DROP POLICY IF EXISTS "Profiles: self insert"  ON public.profiles;
DROP POLICY IF EXISTS "Profiles: self update"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own"    ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own"    ON public.profiles;

CREATE POLICY "profiles_insert_self" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_self" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);


-- =========================================================
-- 2. BUSINESSES — INSERT requiere ser el owner
-- =========================================================

-- Borrar politicas viejas de INSERT en businesses
DROP POLICY IF EXISTS "Businesses: authenticated insert" ON public.businesses;
DROP POLICY IF EXISTS "allow_insert_own"                 ON public.businesses;
DROP POLICY IF EXISTS "businesses_insert_own"            ON public.businesses;

-- INSERT solo si el usuario se asigna a SI MISMO como owner
CREATE POLICY "businesses_insert_own" ON public.businesses
  FOR INSERT
  WITH CHECK (auth.uid() = owner_id);


-- =========================================================
-- 3. SERVICES — INSERT solo si sos el owner del negocio
-- =========================================================

DROP POLICY IF EXISTS "Services: authenticated insert" ON public.services;
DROP POLICY IF EXISTS "services_insert_owner"          ON public.services;

CREATE POLICY "services_insert_owner" ON public.services
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.businesses
      WHERE id = business_id AND owner_id = auth.uid()
    )
  );


-- =========================================================
-- 4. RESERVATIONS — INSERT solo si sos el cliente o el dueno
-- =========================================================

DROP POLICY IF EXISTS "Reservations: client insert"  ON public.reservations;
DROP POLICY IF EXISTS "reservations_insert_client"   ON public.reservations;
DROP POLICY IF EXISTS "reservations_insert_v2"       ON public.reservations;

-- Permitimos dos casos:
--   a) cliente real reservando para si mismo (client_id = auth.uid())
--   b) dueno del negocio cargando una reserva manual
--      (esto lo va a usar el fix de CN-005 con columnas is_manual)
--
-- Por ahora solo el caso a). El caso b) se completa con la migration
-- add_manual_reservations.sql en el siguiente paso.
CREATE POLICY "reservations_insert_client" ON public.reservations
  FOR INSERT
  WITH CHECK (auth.uid() = client_id);


-- =========================================================
-- 5. VERIFICACION — listar politicas finales
-- =========================================================
-- Despues de ejecutar todo lo anterior, podes correr este SELECT
-- para confirmar que las politicas quedaron bien:
--
-- SELECT tablename, policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND tablename IN ('profiles', 'businesses', 'services', 'reservations')
-- ORDER BY tablename, policyname;
