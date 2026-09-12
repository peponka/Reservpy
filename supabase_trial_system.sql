-- ============================================================================
-- Trial system: 1 free month per business, counted from ITS OWN signup date.
-- Run this once in the Supabase SQL Editor (Dashboard → SQL Editor → New query).
-- ============================================================================

-- 1. New columns on businesses -----------------------------------------------
ALTER TABLE businesses
  ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ
    DEFAULT (now() + interval '30 days'),
  ADD COLUMN IF NOT EXISTS subscription_status TEXT
    DEFAULT 'trial' CHECK (subscription_status IN ('trial', 'active', 'expired')),
  ADD COLUMN IF NOT EXISTS trial_reminder_sent BOOLEAN DEFAULT false;

-- 2. Backfill existing businesses (created before this migration) -----------
--    Each one's trial is computed from ITS OWN created_at, not "today".
UPDATE businesses
SET trial_ends_at = created_at + interval '30 days'
WHERE trial_ends_at IS NULL OR trial_ends_at = (now() + interval '30 days');

-- Businesses already on the paid plan are "active", not "trial".
UPDATE businesses
SET subscription_status = 'active'
WHERE plan = 'pro';

-- Businesses whose backfilled trial has already elapsed are "expired".
UPDATE businesses
SET subscription_status = 'expired'
WHERE plan != 'pro'
  AND trial_ends_at < now();

-- 3. Daily cron job: reminders (7 days out) + auto-expiry --------------------
--    Replace <SERVICE_ROLE_KEY> with the project's service_role key
--    (Dashboard → Project Settings → API) before running this block.
select cron.schedule(
  'trial-reminders-daily',
  '0 12 * * *',   -- 12:00 UTC = 09:00 Asunción, every day
  $$
  select net.http_post(
    url := 'https://cmntfqsruljhlgqirtkw.supabase.co/functions/v1/trial-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <SERVICE_ROLE_KEY>'
    ),
    body := '{}'::jsonb
  );
  $$
);
