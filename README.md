# App Early Learning




## EDU Schema setting in Supabase

-- 1. Grant schema usage
GRANT USAGE ON SCHEMA edu TO anon, authenticated;

-- 2. Grant execute on all existing functions in edu
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA edu TO anon, authenticated;

-- 3. Grant execute on future functions automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA edu
    GRANT EXECUTE ON FUNCTIONS TO anon, authenticated;

-- 4. If your functions also SELECT from edu tables directly
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA edu TO authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA edu
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;