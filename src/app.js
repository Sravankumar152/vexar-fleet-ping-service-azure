"use strict";

const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const pinoHttp = require("pino-http");

const config = require("./config");
const logger = require("./logger");
const defaultDb = require("./db");

const healthRoutes = require("./routes/health");
const authRoutes = require("./routes/auth");
const fleetRoutes = require("./routes/fleet");
const adminRoutes = require("./routes/admin");

/**
 * Build the Express app. `db` is injectable so tests can pass a fake and never
 * touch a real database.
 */
function createApp({ db = defaultDb } = {}) {
  const app = express();

  // Behind the AKS ingress/load balancer — trust it for correct client IPs.
  app.set("trust proxy", 1);
  app.disable("x-powered-by");

  // Security headers.
  app.use(helmet());

  // Per-request structured logging with a correlation id.
  app.use(
    pinoHttp({
      logger,
      // Health probes are noisy; log them at debug only.
      autoLogging: {
        ignore: (req) => req.url === "/healthz" || req.url === "/readyz",
      },
    }),
  );

  // Bounded JSON body — reject oversized payloads.
  app.use(express.json({ limit: "16kb" }));

  // Global rate limit (protects auth + ingestion from abuse/storms).
  app.use(
    rateLimit({
      windowMs: config.rateLimit.windowMs,
      max: config.rateLimit.max,
      standardHeaders: true,
      legacyHeaders: false,
    }),
  );

  // Health/readiness are unauthenticated and mounted at the root.
  app.use("/", healthRoutes({ db }));

  app.get("/", (req, res) => {
    res.json({ service: "vexardrive-fleet-ping", status: "running" });
  });

  app.use("/api/auth", authRoutes({ db }));
  app.use("/api/fleet", fleetRoutes({ db }));
  app.use("/api/admin", adminRoutes({ db }));

  // 404.
  app.use((req, res) => {
    res.status(404).json({ error: "not found" });
  });

  // Central error handler — logs the real error, returns a generic message so
  // internals/stack traces never leak to clients.
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    (req.log || logger).error({ err }, "unhandled request error");
    res.status(500).json({ error: "internal server error" });
  });

  return app;
}

module.exports = { createApp };
