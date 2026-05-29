-- ReservPy - Schema completo para Supabase

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('client', 'business', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Profiles: public read" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles: self insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Profiles: self update" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  icon TEXT NOT NULL DEFAULT 'category',
  color TEXT NOT NULL DEFAULT '#00C896',
  sort_order INT NOT NULL DEFAULT 50,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories: public read" ON public.categories FOR SELECT USING (true);
CREATE POLICY "Categories: authenticated insert" ON public.categories FOR INSERT TO authenticated WITH CHECK (true);

-- 3. BUSINESSES
CREATE TABLE IF NOT EXISTS public.businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  phone TEXT,
  website TEXT,
  logo_url TEXT,
  photos TEXT[] DEFAULT '{}',
  opening_time TIME NOT NULL DEFAULT '09:00',
  closing_time TIME NOT NULL DEFAULT '18:00',
  slot_duration_minutes INT NOT NULL DEFAULT 30,
  is_active BOOLEAN NOT NULL DEFAULT true,
  cancellation_hours_policy INT NOT NULL DEFAULT 2,
  reminders_enabled BOOLEAN NOT NULL DEFAULT true,
  reminder_hours_before INT[] DEFAULT '{24}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Businesses: public read" ON public.businesses FOR SELECT USING (is_active = true OR owner_id = auth.uid());
CREATE POLICY "Businesses: authenticated insert" ON public.businesses FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Businesses: owner update" ON public.businesses FOR UPDATE USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Businesses: owner delete" ON public.businesses FOR DELETE USING (auth.uid() = owner_id);

-- 4. SERVICES
CREATE TABLE IF NOT EXISTS public.services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  duration_minutes INT NOT NULL DEFAULT 30,
  price DOUBLE PRECISION,
  currency TEXT NOT NULL DEFAULT 'PYG',
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Services: public read" ON public.services FOR SELECT USING (true);
CREATE POLICY "Services: authenticated insert" ON public.services FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Services: owner update" ON public.services FOR UPDATE USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid()));
CREATE POLICY "Services: owner delete" ON public.services FOR DELETE USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid()));

-- 5. RESERVATIONS
CREATE TABLE IF NOT EXISTS public.reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  notes TEXT,
  cancellation_reason TEXT,
  client_name TEXT,
  service_name TEXT,
  business_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reservations: read own" ON public.reservations FOR SELECT USING (client_id = auth.uid() OR EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid()));
CREATE POLICY "Reservations: client insert" ON public.reservations FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Reservations: update own" ON public.reservations FOR UPDATE USING (client_id = auth.uid() OR EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid()));

-- 6. BLOCKED SLOTS
CREATE TABLE IF NOT EXISTS public.blocked_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blocked_slots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Blocked slots: public read" ON public.blocked_slots FOR SELECT USING (true);
CREATE POLICY "Blocked slots: owner manage" ON public.blocked_slots FOR ALL USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid()));

-- 7. EMPLOYEES
CREATE TABLE IF NOT EXISTS public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'staff',
  avatar_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Employees: public read" ON public.employees FOR SELECT USING (true);
CREATE POLICY "Employees: owner manage" ON public.employees FOR ALL USING (EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id AND owner_id = auth.uid()));

-- 8. INDEXES
CREATE INDEX IF NOT EXISTS idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_businesses_category ON public.businesses(category_id);
CREATE INDEX IF NOT EXISTS idx_services_business ON public.services(business_id);
CREATE INDEX IF NOT EXISTS idx_reservations_business ON public.reservations(business_id);
CREATE INDEX IF NOT EXISTS idx_reservations_client ON public.reservations(client_id);
CREATE INDEX IF NOT EXISTS idx_reservations_start ON public.reservations(start_time);
CREATE INDEX IF NOT EXISTS idx_blocked_slots_business ON public.blocked_slots(business_id);
CREATE INDEX IF NOT EXISTS idx_employees_business ON public.employees(business_id);

-- 9. SEED CATEGORIES (25)
INSERT INTO public.categories (name, icon, color, sort_order) VALUES
  ('Peluqueria / Barberia', 'content_cut', '#FF7043', 1),
  ('Belleza y estetica', 'spa', '#E040FB', 2),
  ('Salud', 'local_hospital', '#4FC3F7', 3),
  ('Odontologia', 'medical_services', '#26C6DA', 4),
  ('Psicologia / Terapia', 'psychology', '#7E57C2', 5),
  ('Nutricion', 'restaurant', '#66BB6A', 6),
  ('Veterinaria', 'pets', '#8D6E63', 7),
  ('Fitness / Gimnasio', 'fitness_center', '#EF5350', 8),
  ('Yoga / Pilates', 'self_improvement', '#26A69A', 9),
  ('Masajes / Spa', 'spa', '#AB47BC', 10),
  ('Consultorio medico', 'local_hospital', '#42A5F5', 11),
  ('Restaurante / Cafe', 'restaurant', '#FF7043', 12),
  ('Abogados / Notaria', 'business_center', '#78909C', 13),
  ('Contabilidad', 'business_center', '#5C6BC0', 14),
  ('Fotografia', 'camera_alt', '#EC407A', 15),
  ('Tatuajes / Piercing', 'auto_awesome', '#455A64', 16),
  ('Mecanica automotriz', 'build', '#FF8A65', 17),
  ('Educacion / Tutorias', 'school', '#29B6F6', 18),
  ('Consultoria', 'business_center', '#42A5F5', 19),
  ('Inmobiliaria', 'business_center', '#26A69A', 20),
  ('Limpieza', 'cleaning_services', '#66BB6A', 21),
  ('Electronica / Reparacion', 'build', '#FF9800', 22),
  ('Deportes / Canchas', 'sports_soccer', '#4CAF50', 23),
  ('Eventos / Catering', 'celebration', '#E91E63', 24),
  ('Otros', 'category', '#90A4AE', 25)
ON CONFLICT (name) DO NOTHING;
