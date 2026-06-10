-- ================================================================
-- ReservPy — Admin Panel v2 Schema
-- Ejecutar en: Supabase Dashboard → SQL Editor → New Query
-- ================================================================

-- Helper function: obtiene el rol del usuario autenticado
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM team_members
  WHERE user_id = auth.uid() AND status = 'active'
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

-- ── 1. TEAM MEMBERS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS team_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  email           TEXT NOT NULL UNIQUE,
  full_name       TEXT,
  role            TEXT NOT NULL DEFAULT 'soporte'
                    CHECK (role IN ('super_admin','admin','manager','soporte')),
  status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('active','pending','revoked')),
  invite_token    TEXT UNIQUE,
  invite_expires  TIMESTAMPTZ,
  invited_by      UUID REFERENCES auth.users(id),
  invited_at      TIMESTAMPTZ DEFAULT now(),
  accepted_at     TIMESTAMPTZ,
  last_login_at   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tm_email  ON team_members(email);
CREATE INDEX IF NOT EXISTS idx_tm_status ON team_members(status);
CREATE INDEX IF NOT EXISTS idx_tm_role   ON team_members(role);

-- Insertar super admin automáticamente
INSERT INTO team_members (email, full_name, role, status)
VALUES ('pepeq68@gmail.com', 'Super Admin', 'super_admin', 'active')
ON CONFLICT (email) DO UPDATE SET role = 'super_admin', status = 'active';

-- ── 2. PLANS ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS plans (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL UNIQUE,
  slug            TEXT NOT NULL UNIQUE,
  price_monthly   NUMERIC(12,2) NOT NULL DEFAULT 0,
  price_yearly    NUMERIC(12,2),
  currency        TEXT NOT NULL DEFAULT 'PYG',
  features        JSONB DEFAULT '[]',
  max_reservations INT,
  is_active       BOOLEAN DEFAULT true,
  is_default      BOOLEAN DEFAULT false,
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Planes por defecto
INSERT INTO plans (name, slug, price_monthly, price_yearly, currency, is_default, sort_order, features)
VALUES
  ('Gratuito',   'free',       0,      0,       'PYG', true,  0,
   '["Hasta 50 reservas/mes","1 servicio","Sin soporte prioritario"]'),
  ('Básico',     'basic',  25000, 270000,        'PYG', false, 1,
   '["Hasta 200 reservas/mes","5 servicios","Soporte por email"]'),
  ('Pro',        'pro',    75000, 810000,        'PYG', false, 2,
   '["Reservas ilimitadas","Servicios ilimitados","Soporte prioritario","Reportes avanzados"]'),
  ('Enterprise', 'enterprise', 200000, 2160000, 'PYG', false, 3,
   '["Todo lo de Pro","API acceso","Manager dedicado","SLA garantizado"]')
ON CONFLICT (slug) DO NOTHING;

-- ── 3. PAYMENTS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id          UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  plan_id              UUID REFERENCES plans(id),
  amount               NUMERIC(12,2) NOT NULL,
  currency             TEXT NOT NULL DEFAULT 'PYG',
  billing_period_start DATE,
  billing_period_end   DATE,
  payment_method       TEXT CHECK (payment_method IN
                         ('transferencia','tigo_money','bancard','efectivo','credito','otro')),
  reference            TEXT,
  status               TEXT NOT NULL DEFAULT 'pending'
                         CHECK (status IN ('paid','pending','overdue','cancelled','refunded')),
  due_date             DATE NOT NULL,
  paid_at              TIMESTAMPTZ,
  registered_by        UUID REFERENCES auth.users(id),
  notes                TEXT,
  created_at           TIMESTAMPTZ DEFAULT now(),
  updated_at           TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payments_business_id ON payments(business_id);
CREATE INDEX IF NOT EXISTS idx_payments_status      ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_due_date    ON payments(due_date);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at     ON payments(paid_at);

-- ── 4. PAYMENT REMINDERS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payment_reminders (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id  UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  sent_by     UUID REFERENCES auth.users(id),
  sent_at     TIMESTAMPTZ DEFAULT now(),
  method      TEXT DEFAULT 'email' CHECK (method IN ('email','whatsapp','manual')),
  notes       TEXT
);
CREATE INDEX IF NOT EXISTS idx_reminders_business_id ON payment_reminders(business_id);
CREATE INDEX IF NOT EXISTS idx_reminders_payment_id  ON payment_reminders(payment_id);

-- ── 5. TEAM ACTIVITY LOG ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS team_activity_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id),
  user_email    TEXT,
  action        TEXT NOT NULL,
  entity_type   TEXT,
  entity_id     TEXT,
  entity_name   TEXT,
  description   TEXT,
  metadata      JSONB DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_log_user_id    ON team_activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_log_entity     ON team_activity_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_log_created_at ON team_activity_log(created_at DESC);

-- ── 6. EMAIL TEMPLATES ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS email_templates (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT NOT NULL UNIQUE,
  name        TEXT NOT NULL,
  subject     TEXT NOT NULL,
  body_text   TEXT NOT NULL,
  variables   JSONB DEFAULT '[]',
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

INSERT INTO email_templates (slug, name, subject, body_text, variables) VALUES
('payment_reminder',
 'Recordatorio de Pago',
 'Recordatorio: Tu suscripción a Reservpy vence pronto',
 'Hola {{business_name}},\n\nTe recordamos que tu suscripción al plan {{plan_name}} vence el {{due_date}}.\n\nMonto: ₲ {{amount}}\n\nGracias,\nEquipo Reservpy',
 '["business_name","plan_name","due_date","amount"]'),
('payment_overdue',
 'Pago Vencido',
 'Tu suscripción a Reservpy está vencida',
 'Hola {{business_name}},\n\nTu suscripción al plan {{plan_name}} venció hace {{days_overdue}} días.\n\nPor favor regularizá tu situación para continuar usando el servicio.\n\nGracias,\nEquipo Reservpy',
 '["business_name","plan_name","days_overdue"]'),
('welcome',
 'Bienvenido a Reservpy',
 '¡Bienvenido a Reservpy, {{business_name}}!',
 'Hola {{business_name}},\n\nBienvenido a Reservpy. Tu cuenta ha sido creada exitosamente.\n\nPlan: {{plan_name}}\nAcceso: {{app_url}}\n\n¡Muchas gracias!',
 '["business_name","plan_name","app_url"]')
ON CONFLICT (slug) DO NOTHING;

-- ── VISTAS ──────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_overdue_payments AS
SELECT
  b.id               AS business_id,
  b.name             AS business_name,
  b.email            AS business_email,
  b.is_active,
  b.plan             AS current_plan,
  p.id               AS payment_id,
  p.amount,
  p.currency,
  p.due_date,
  CURRENT_DATE - p.due_date AS days_overdue,
  CASE
    WHEN CURRENT_DATE - p.due_date BETWEEN 1  AND 7  THEN 'leve'
    WHEN CURRENT_DATE - p.due_date BETWEEN 8  AND 30 THEN 'moderado'
    WHEN CURRENT_DATE - p.due_date > 30               THEN 'critico'
    ELSE 'leve'
  END AS severity,
  (
    SELECT MAX(sent_at) FROM payment_reminders pr
    WHERE pr.business_id = b.id AND pr.payment_id = p.id
  ) AS last_reminder_sent
FROM businesses b
JOIN payments p ON p.business_id = b.id
WHERE p.status = 'overdue'
  AND b.is_active = true
ORDER BY days_overdue DESC;

CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT
  DATE_TRUNC('month', paid_at) AS month,
  COUNT(*)                      AS payment_count,
  SUM(amount)                   AS total_revenue,
  currency
FROM payments
WHERE status = 'paid' AND paid_at IS NOT NULL
GROUP BY DATE_TRUNC('month', paid_at), currency
ORDER BY month DESC;

-- ── TRIGGER: auto-log en businesses y payments ──────────────────

CREATE OR REPLACE FUNCTION auto_log_changes()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO team_activity_log (user_id, user_email, action, entity_type, entity_id, entity_name, description)
  VALUES (
    auth.uid(),
    (SELECT email FROM auth.users WHERE id = auth.uid()),
    TG_OP || '.' || TG_TABLE_NAME,
    TG_TABLE_NAME,
    COALESCE(NEW.id::TEXT, OLD.id::TEXT),
    COALESCE(NEW.name, NEW.business_name, ''),
    TG_OP || ' on ' || TG_TABLE_NAME
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER log_payments_changes
  AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION auto_log_changes();

-- ── RLS ─────────────────────────────────────────────────────────

ALTER TABLE team_members       ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_reminders  ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_activity_log  ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans              ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates    ENABLE ROW LEVEL SECURITY;

-- team_members: solo admins gestionan equipo
DROP POLICY IF EXISTS "admin_manage_team" ON team_members;
CREATE POLICY "admin_manage_team" ON team_members
  FOR ALL USING (get_my_role() IN ('super_admin','admin'));

-- payments: lectura para equipo (excepto soporte), escritura para admins
DROP POLICY IF EXISTS "team_read_payments"  ON payments;
DROP POLICY IF EXISTS "admin_write_payments" ON payments;
CREATE POLICY "team_read_payments" ON payments
  FOR SELECT USING (get_my_role() IN ('super_admin','admin','manager'));
CREATE POLICY "admin_write_payments" ON payments
  FOR ALL USING (get_my_role() IN ('super_admin','admin'));

-- payment_reminders
DROP POLICY IF EXISTS "team_manage_reminders" ON payment_reminders;
CREATE POLICY "team_manage_reminders" ON payment_reminders
  FOR ALL USING (get_my_role() IN ('super_admin','admin','manager'));

-- activity log
DROP POLICY IF EXISTS "admin_read_log"  ON team_activity_log;
DROP POLICY IF EXISTS "team_insert_log" ON team_activity_log;
CREATE POLICY "admin_read_log" ON team_activity_log
  FOR SELECT USING (get_my_role() IN ('super_admin','admin'));
CREATE POLICY "team_insert_log" ON team_activity_log
  FOR INSERT WITH CHECK (get_my_role() IS NOT NULL);

-- plans: lectura pública, escritura solo admin
DROP POLICY IF EXISTS "public_read_plans"  ON plans;
DROP POLICY IF EXISTS "admin_write_plans"  ON plans;
CREATE POLICY "public_read_plans" ON plans  FOR SELECT USING (true);
CREATE POLICY "admin_write_plans" ON plans  FOR ALL USING (get_my_role() IN ('super_admin','admin'));

-- email_templates
DROP POLICY IF EXISTS "admin_manage_templates" ON email_templates;
CREATE POLICY "admin_manage_templates" ON email_templates
  FOR ALL USING (get_my_role() IN ('super_admin','admin'));
