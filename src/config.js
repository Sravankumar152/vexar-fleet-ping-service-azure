"use strict";

/**
 * Centralised, validated configuration. All settings come from the
 * environment — nothing is hardcoded. Missing required values fail fast at
 * startup (in production) rather than surfacing as confusing runtime errors.
 */

// Load .env only outside production; in prod, env is injected (Key Vault/CSI).
if (process.env.NODE_ENV !== "production") {
  try {
    require("dotenv").config();
  } catch {
    /* dotenv is a devDependency; ignore if absent */
  }
}

function required(name) {
  const v = process.env[name];
  if (v === undefined || v === "") {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return v;
}

function optional(name, fallback) {
  const v = process.env[name];
  return v === undefined || v === "" ? fallback : v;
}

function int(name, fallback) {
  const v = process.env[name];
  if (v === undefined || v === "") return fallback;
  const n = Number(v);
  if (!Number.isFinite(n)) throw new Error(`Env ${name} must be a number`);
  return n;
}

const isProd = process.env.NODE_ENV === "production";

// In production, secrets MUST be present. In dev/test we allow fallbacks so
// the app and tests can run without a real secret store.
const jwtSecret = isProd
  ? required("JWT_SECRET")
  : optional("JWT_SECRET", "dev-only-insecure-secret");

const database = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL }
  : {
      host: optional("PGHOST", "localhost"),
      port: int("PGPORT", 5432),
      database: optional("PGDATABASE", "vexar_fleet"),
      user: optional("PGUSER", "fleet_app"),
      password: optional("PGPASSWORD", ""),
    };

const sslMode = optional("PGSSLMODE", "disable");
if (sslMode && sslMode !== "disable") {
  // Azure PostgreSQL requires TLS; verify-full is preferable with a CA bundle.
  database.ssl = { rejectUnauthorized: sslMode === "verify-full" };
}

const config = Object.freeze({
  env: process.env.NODE_ENV || "development",
  isProd,
  port: int("PORT", 3000),
  logLevel: optional("LOG_LEVEL", "info"),
  corsOrigins: optional("CORS_ORIGINS", "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean),

  database,

  pool: {
    max: int("PG_POOL_MAX", 10),
    idleTimeoutMillis: int("PG_IDLE_TIMEOUT_MS", 30000),
    connectionTimeoutMillis: int("PG_CONNECTION_TIMEOUT_MS", 5000),
    statement_timeout: int("PG_STATEMENT_TIMEOUT_MS", 10000),
  },

  jwt: {
    secret: jwtSecret,
    expiresIn: optional("JWT_EXPIRES_IN", "30d"),
  },

  rateLimit: {
    windowMs: int("RATE_LIMIT_WINDOW_MS", 60000),
    max: int("RATE_LIMIT_MAX", 120),
  },

  otp: {
    ttlSeconds: int("OTP_TTL_SECONDS", 300),
    maxAttempts: int("OTP_MAX_ATTEMPTS", 5),
    length: 6,
  },
});

module.exports = config;
