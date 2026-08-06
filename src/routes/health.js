"use strict";

const express = require("express");

/**
 * Liveness vs readiness are deliberately different:
 * - /healthz (liveness): is the process up? Never touches the DB, so a DB
 *   blip doesn't cause Kubernetes to kill and restart healthy pods.
 * - /readyz (readiness): can we actually serve traffic? Checks the DB, so an
 *   unready pod is pulled from the load balancer until its dependency recovers.
 */
module.exports = function healthRoutes({ db }) {
  const router = express.Router();

  router.get("/healthz", (req, res) => {
    res.json({ status: "ok", uptime: process.uptime() });
  });

  router.get("/readyz", async (req, res) => {
    try {
      await db.healthCheck();
      res.json({ status: "ready" });
    } catch (err) {
      req.log?.warn({ err }, "readiness check failed");
      res.status(503).json({ status: "not ready" });
    }
  });

  return router;
};
