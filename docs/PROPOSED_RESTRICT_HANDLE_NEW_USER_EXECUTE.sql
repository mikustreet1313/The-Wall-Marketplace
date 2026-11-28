-- THE WALL ! — proposed least-privilege adjustment
-- Purpose: remove the default PUBLIC EXECUTE privilege from the trigger-only
-- function public.handle_new_user().
--
-- IMPORTANT:
--   * Review this file before running it in Supabase.
--   * This is a proposed migration; it has NOT been executed.
--   * Do not drop/recreate the trigger.
--   * PostgreSQL checks EXECUTE permission when CREATE TRIGGER is issued;
--     the existing trigger does not need PUBLIC EXECUTE at each row insert.
--   * The function owner (postgres) retains owner privileges.
--
-- Pre-check: inspect the function's current ACL and effective privileges.
SELECT
  p.oid::regprocedure AS function_name,
  pg_get_userbyid(p.proowner) AS owner,
  p.proacl AS explicit_acl,
  has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_can_execute,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_can_execute,
  has_function_privilege('service_role', p.oid, 'EXECUTE') AS service_role_can_execute,
  has_function_privilege('supabase_auth_admin', p.oid, 'EXECUTE') AS auth_admin_can_execute
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'handle_new_user'
  AND pg_get_function_identity_arguments(p.oid) = '';

-- Change: remove the default function EXECUTE grant from PUBLIC.
-- This prevents roles such as anon/authenticated/service_role from inheriting
-- EXECUTE solely through PUBLIC. The existing auth.users trigger is retained.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;

-- Post-check: verify the effective privileges after the REVOKE.
SELECT
  rolname AS database_role,
  has_function_privilege(rolname, 'public.handle_new_user()', 'EXECUTE') AS can_execute
FROM pg_roles
WHERE rolname IN (
  'anon',
  'authenticated',
  'service_role',
  'postgres',
  'supabase_auth_admin'
)
ORDER BY rolname;

-- Expected baseline:
--   postgres = true (function owner)
--   anon = false
--   authenticated = false
--   service_role = false
--   supabase_auth_admin = false, unless a separate direct grant or inherited
--     membership independently grants EXECUTE.
--
-- If supabase_auth_admin remains true, inspect role memberships and function
-- ACLs before taking any additional action. Do not blindly revoke from it.
--
-- After applying in a controlled window, test a new test-account registration
-- and confirm public.profiles row creation still succeeds.
