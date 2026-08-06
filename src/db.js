"use strict";

/**
 * A single shared connection pool for the whole process.
 *
 * The original code opened and tore down a brand-new client on EVERY request —
 * fatal under bursty fleet-ping traffic. A pool reuses a bounded set of
 * connections (and in Azure sits behind PgBouncer), protecting the database
 * from connection storms.
 */
const { Pool } = require("pg");
const config = require("./config");
const logger = require("./logger");

const pool = new Pool({
  ...config.database,
  max: config.pool.max,
  idleTimeoutMillis: config.pool.idleTimeoutMillis,
  connectionTimeoutMillis: config.pool.connectionTimeoutMillis,
  statement_timeout: config.pool.statement_timeout,
});

// A pool-level error (e.g. backend crash) must not take the process down.
pool.on("error", (err) => {
  logger.error({ err }, "Unexpected idle client error in pg pool");
});

/** Parameterised query helper — always use placeholders, never string concat. */
function query(text, params) {
  return pool.query(text, params);
}

/** Readiness probe dependency: is the database reachable right now? */
async function healthCheck() {
  const res = await pool.query("SELECT 1 AS ok");
  return res.rows[0].ok === 1;
}

async function close() {
  await pool.end();
}

module.exports = { pool, query, healthCheck, close };
