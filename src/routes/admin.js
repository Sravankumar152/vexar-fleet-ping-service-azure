"use strict";

const express = require("express");
const { requireAuth, requireRole } = require("../auth");

/**
 * Admin driver listing. Originally this returned ALL driver rows with NO auth
 * whatsoever. Now it requires a valid JWT AND the `admin` role, and paginates
 * instead of dumping the whole table.
 *
 * Admin token issuance is a separate privileged flow (SSO/staff IdP) and is
 * out of scope here — the point is the endpoint is no longer world-readable.
 */
module.exports = function adminRoutes({ db }) {
  const router = express.Router();

  router.get(
    "/drivers",
    requireAuth,
    requireRole("admin"),
    async (req, res, next) => {
      try {
        const limit = Math.min(Number(req.query.limit) || 50, 200);
        const offset = Math.max(Number(req.query.offset) || 0, 0);
        const { rows } = await db.query(
          `SELECT id, phone, name, created_at
             FROM drivers
             ORDER BY id
             LIMIT $1 OFFSET $2`,
          [limit, offset],
        );
        res.json({ drivers: rows, limit, offset });
      } catch (err) {
        next(err);
      }
    },
  );

  return router;
};
