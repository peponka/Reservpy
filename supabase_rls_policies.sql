-- ============================================================
-- ReservPy: Row-Level Security Policies
-- Run this ONCE in Supabase SQL Editor to configure all RLS
-- ============================================================

-- 1. PROFILES (id = auth.uid())
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
-- Allow joins from reservations (business owners need to see client names)
CREATE POLICY "profiles_select_for_joins" ON profiles FOR SELECT USING (true);

-- 2. USER_ROLES (user_id = auth.uid())
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can read own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can insert own roles" ON user_roles;
CREATE POLICY "user_roles_select_own" ON user_roles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_roles_insert_own" ON user_roles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_roles_delete_own" ON user_roles FOR DELETE USING (auth.uid() = user_id);

-- 3. BUSINESSES (owner_id = auth.uid())
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_insert_own" ON businesses;
DROP POLICY IF EXISTS "allow_select_all" ON businesses;
DROP POLICY IF EXISTS "allow_update_own" ON businesses;
DROP POLICY IF EXISTS "allow_delete_own" ON businesses;
CREATE POLICY "businesses_select_all" ON businesses FOR SELECT USING (true);
CREATE POLICY "businesses_insert_own" ON businesses FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "businesses_update_own" ON businesses FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "businesses_delete_own" ON businesses FOR DELETE USING (auth.uid() = owner_id);

-- 4. SERVICES (business_id -> businesses.owner_id)
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
CREATE POLICY "services_select_all" ON services FOR SELECT USING (true);
CREATE POLICY "services_insert_owner" ON services FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));
CREATE POLICY "services_update_owner" ON services FOR UPDATE
  USING (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));
CREATE POLICY "services_delete_owner" ON services FOR DELETE
  USING (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));

-- 5. EMPLOYEES (business_id -> businesses.owner_id)
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "employees_select_owner" ON employees FOR SELECT
  USING (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));
CREATE POLICY "employees_insert_owner" ON employees FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));
CREATE POLICY "employees_update_owner" ON employees FOR UPDATE
  USING (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));
CREATE POLICY "employees_delete_owner" ON employees FOR DELETE
  USING (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));

-- 6. BLOCKED_SLOTS (business_id -> businesses.owner_id)
ALTER TABLE blocked_slots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "blocked_slots_select_owner" ON blocked_slots FOR SELECT
  USING (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));
CREATE POLICY "blocked_slots_insert_owner" ON blocked_slots FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));
CREATE POLICY "blocked_slots_delete_owner" ON blocked_slots FOR DELETE
  USING (EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid()));

-- 7. RESERVATIONS (dual access: business owner + client)
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reservations_select_own" ON reservations FOR SELECT
  USING (
    auth.uid() = client_id
    OR EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid())
  );
CREATE POLICY "reservations_insert_client" ON reservations FOR INSERT
  WITH CHECK (auth.uid() = client_id);
CREATE POLICY "reservations_update_access" ON reservations FOR UPDATE
  USING (
    auth.uid() = client_id
    OR EXISTS (SELECT 1 FROM businesses WHERE businesses.id = business_id AND businesses.owner_id = auth.uid())
  );

-- 8. CATEGORIES (public lookup table)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "categories_select_all" ON categories FOR SELECT USING (true);
CREATE POLICY "categories_insert_authenticated" ON categories FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
