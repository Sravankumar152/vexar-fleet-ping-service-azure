"use strict";

/**
 * Process entry point: start the HTTP server and shut it down cleanly.
 *
 * Graceful shutdown matters on Kubernetes: on a rolling update the pod gets
 * SIGTERM, so we stop accepting new connections, let in-flight requests drain,
 * close the DB pool, then exit — no dropped fleet pings mid-deploy.
 */
const { createApp } = require("./src/app");
const db = require("./src/db");
const config = require("./src/config");
const logger = require("./src/logger");

const app = createApp({ db });

const server = app.listen(config.port, () => {
  logger.info({ port: config.port, env: config.env }, "server listening");
});

// Fail fast on process-level errors after logging them.
process.on("unhandledRejection", (reason) => {
  logger.error({ err: reason }, "unhandledRejection");
});
process.on("uncaughtException", (err) => {
  logger.fatal({ err }, "uncaughtException — exiting");
  process.exit(1);
});

let shuttingDown = false;
async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  logger.info({ signal }, "shutting down");

  // Force-exit backstop if draining hangs.
  const force = setTimeout(() => {
    logger.error("graceful shutdown timed out — forcing exit");
    process.exit(1);
  }, 15000);
  force.unref();

  server.close(async () => {
    try {
      await db.close();
      logger.info("shutdown complete");
      process.exit(0);
    } catch (err) {
      logger.error({ err }, "error during shutdown");
      process.exit(1);
    }
  });
}

["SIGTERM", "SIGINT"].forEach((sig) => process.on(sig, () => shutdown(sig)));

module.exports = server;
