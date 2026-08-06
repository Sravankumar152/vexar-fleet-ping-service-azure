"use strict";

const express = require("express");
const { requireAuth } = require("../auth");
const { validateBody, pingSchema } = require("../validation");

/**
 * Vehicle ping ingestion — the hot path. Now:
 * - authenticated (was open),
 * - fully validated (bounds-checked lat/lng/speed),
 * - parameterised INSERT via the shared pool (was a new client per request).
 *
 * A device-scoped credential would be the fuller design; the driver JWT is
 * used here and the trade-off is noted in the report.
 */
module.exports = function fleetRoutes({ db }) {
  const router = express.Router();

  router.post(
    "/ping",
    requireAuth,
    validateBody(pingSchema),
    async (req, res, next) => {
      try {
        const { vehicleId, lat, lng, speed, timestamp } = req.validated;
        await db.query(
          `INSERT INTO fleet_pings (vehicle_id, lat, lng, speed, ts)
           VALUES ($1, $2, $3, $4, $5)`,
          [vehicleId, lat, lng, speed ?? null, timestamp ?? new Date()],
        );
        res.status(202).json({ status: "accepted" });
      } catch (err) {
        next(err);
      }
    },
  );

  return router;
};
