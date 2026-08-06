#!/usr/bin/env node
/**
 * Minimal, dependency-light SQL migration runner.
 *
 * - Applies db/migrations/*.sql in filename order.
 * - Each migration runs inside its own transaction.
 * - Applied migrations are recorded in schema_migrations (idempotent reruns).
 *
 * Connection comes from the same env as the app (DATABASE_URL or PG* vars),
 * so in production it is invoked as a Kubernetes Job / init step using the
 * Key Vault-sourced connection string. Run locally with `npm run db:migrate`.
 */
const fs = require("fs");
const path = require("path");
const { Client } = require("pg");

const MIGRATIONS_DIR = path.join(__dirname, "..", "db", "migrations");

function clientConfig() {
  if (process.env.DATABASE_URL) {
    return { connectionString: process.env.DATABASE_URL };
  }
  return {
    host: process.env.PGHOST,
    port: Number(process.env.PGPORT || 5432),
    user: process.env.PGUSER,
    password: process.env.PGPASSWORD,
    database: process.env.PGDATABASE,
    ssl:
      process.env.PGSSLMODE && process.env.PGSSLMODE !== "disable"
        ? { rejectUnauthorized: false }
        : undefined,
  };
}

async function main() {
  const client = new Client(clientConfig());
  await client.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version    TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    `);

    const applied = new Set(
      (await client.query("SELECT version FROM schema_migrations")).rows.map(
        (r) => r.version,
      ),
    );

    const files = fs
      .readdirSync(MIGRATIONS_DIR)
      .filter((f) => f.endsWith(".sql"))
      .sort();

    let count = 0;
    for (const file of files) {
      if (applied.has(file)) continue;
      const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), "utf8");
      process.stdout.write(`Applying ${file} ... `);
      await client.query("BEGIN");
      try {
        await client.query(sql);
        await client.query(
          "INSERT INTO schema_migrations (version) VALUES ($1)",
          [file],
        );
        await client.query("COMMIT");
        console.log("done");
        count += 1;
      } catch (err) {
        await client.query("ROLLBACK");
        throw new Error(`Migration ${file} failed: ${err.message}`);
      }
    }
    console.log(count === 0 ? "No pending migrations." : `Applied ${count} migration(s).`);
  } finally {
    await client.end();
  }
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
