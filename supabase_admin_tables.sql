-- ============================================================
-- ReservPy Admin System — New Tables
-- Run this in: Supabase Dashboard > SQL Editor > New Query
-- ============================================================

-- 1. Audit Logs — tracks every admin action
CREATE TABLE IF NOT EXISTS audit_logs (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email    TEXT,
  action        TEXT        NOT NULL,  -- e.g. 'business.deactivate', 'user.role_change'
  entity_type   TEXT,                  -- 'business', 'user', 'subscription', etc.
  entity_id     TEXT,
  entity_name   TEXT,
  details       JSONB       DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS audit_logs_user_id_idx    ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS audit_logs_created_at_idx ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS audit_logs_action_idx     ON audit_logs(action);

-- 2. Admin Team Members — platform internal team
CREATE TABLE IF NOT EXISTS admin_team_members (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT        NOT NULL,
  first_name    TEXT        DEFAULT '',
  last_name     TEXT        DEFAULT '',
  admin_role    TEXT        NOT NULL DEFAULT 'operator',
    -- Values: super_admin | admin | manager | operator | support
  permissions   JSONB       DEFAULT '{
    "can_view_clients":        true,
    "can_edit_clients":        false,
    "can_delete_clients":      false,
    "can_view_metrics":        true,
    "can_view_billing":        false,
    "can_manage_subscriptions":false,
    "can_manage_team":         false,
    "can_view_audit_logs":     false
  }',
  is_active     BOOLEAN     DEFAULT true,
  last_login    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT now(),
  created_by    UUID        REFERENCES auth.users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS admin_team_members_email_idx ON admin_team_members(email);

-- 3. Business Billing — payment/subscription tracking
CREATE TABLE IF NOT EXISTS business_billing (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id       UUID        NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  plan              TEXT        NOT NULL DEFAULT 'free',
  status            TEXT        NOT NULL DEFAULT 'active',
    -- Values: active | pending | overdue | suspended | cancelled
  amount_guaranies  INTEGER     DEFAULT 0,
  billing_cycle     TEXT        DEFAULT 'monthly', -- monthly | annual
  started_at        TIMESTAMPTZ DEFAULT now(),
  next_billing_at   TIMESTAMPTZ,
  cancelled_at      TIMESTAMPTZ,
  notes             TEXT,
  created_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS business_billing_business_id_idx ON business_billing(business_id);
CREATE INDEX IF NOT EXISTS business_billing_status_idx      ON business_billing(status);
CREATE INDEX IF NOT EXISTS business_billing_next_billing_idx ON business_billing(next_billing_at);

-- ── RLS Policies (allow admin users full access) ──────────────────────────

ALTER TABLE audit_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_billing   ENABLE ROW LEVEL SECURITY;

-- Admin users can do everything (check via user_roles table)
CREATE POLICY "admin_full_access_audit" ON audit_logs
  USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "admin_full_access_team" ON admin_team_members
  USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "admin_full_access_billing" ON business_billing
  USING (
    EXISTS (SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND role = 'admin')
  );

-- ── Seed: Plan prices (Guaraníes) ─────────────────────────────────────────
-- These are reference values used by the app for MRR/ARR calculations.
-- Adjust as needed.

-- free:       0 PYG/month
-- basic:  25000 PYG/month  (~USD 3.5)
-- pro:    75000 PYG/month  (~USD 10)
-- enterprise: 200000 PYG/month (~USD 27)
