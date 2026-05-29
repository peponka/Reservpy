CREATE TABLE IF NOT EXISTS user_roles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('client', 'business_owner', 'employee', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own roles"
  ON user_roles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own roles"
  ON user_roles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

INSERT INTO user_roles (user_id, role)
SELECT profiles.id,
  CASE WHEN profiles.role = 'business' THEN 'business_owner' ELSE 'client' END
FROM profiles
WHERE profiles.role IS NOT NULL
ON CONFLICT (user_id, role) DO NOTHING;

INSERT INTO user_roles (user_id, role)
SELECT user_roles.user_id, 'client'
FROM user_roles
WHERE user_roles.role = 'business_owner'
ON CONFLICT (user_id, role) DO NOTHING;
