# Database

PostgreSQL schema, migrations and roles for the Fleet Ping Service.

## Migrations are authoritative

`db/migrations/*.sql` is the source of truth for schema. They are applied in
filename order by `scripts/migrate.js`, which records each in a
`schema_migrations` table and runs every migration in its own transaction, so
the runner is safe to re-run and safe to run concurrently on deploy.

```bash
npm run db:migrate      # uses DATABASE_URL or PG* env vars
```

In production the migration runs as a Kubernetes **Job** (or an init step)
before the new app version serves traffic, using the same Key Vault-sourced
connection string as the app.

| File | Purpose |
|------|---------|
| `0001_init.sql` | Baseline `drivers` + `fleet_pings` (NOT NULL, `timestamptz`). |
| `0002_fleet_pings_indexes.sql` | Indexes for latest-per-vehicle and time-range reads. |
| `0003_driver_otps.sql` | Hashed, expiring OTP storage (closes the login auth-bypass). |

## Least-privilege role

The application connects as `fleet_app` (see `db/roles/app_role.sql`), which can
only `SELECT/INSERT/UPDATE` the app tables — never the admin login. The role
password comes from Key Vault and is never committed.

## `schema.sql`

A convenience full-schema snapshot for quick local bootstrapping. The
migrations remain authoritative; regenerate the snapshot from a migrated
database if it drifts.
