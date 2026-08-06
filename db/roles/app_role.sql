-- Least-privilege application role.
--
-- The app must NOT connect as the server admin. This creates a role that can
-- only do what the service needs: read/write the two application tables — no
-- DDL, no DROP, no superuser. Run ONCE by an admin/DBA after the database is
-- created and migrations have run.
--
-- The password is supplied out of band from Key Vault; it is intentionally a
-- placeholder here so no credential is committed:
--
--   psql "<admin connection>" \
--     -v app_password="$(az keyvault secret show ... --query value -o tsv)" \
--     -f db/roles/app_role.sql
--
-- Then point the app's DATABASE_URL at this role instead of the admin login.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fleet_app') THEN
    EXECUTE format('CREATE ROLE fleet_app LOGIN PASSWORD %L', :'app_password');
  END IF;
END
$$;

GRANT CONNECT ON DATABASE vexar_fleet TO fleet_app;
GRANT USAGE ON SCHEMA public TO fleet_app;

-- Data-plane only: no DDL rights.
GRANT SELECT, INSERT, UPDATE ON drivers, fleet_pings, driver_otps TO fleet_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO fleet_app;

-- Ensure future tables created by migrations are usable without re-granting.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE ON TABLES TO fleet_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO fleet_app;
