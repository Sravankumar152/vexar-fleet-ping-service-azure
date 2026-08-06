"use strict";

/**
 * JWT issuance + verification middleware.
 * The original admin endpoint had NO auth at all; this middleware is applied to
 * protected routes and rejects missing/invalid/expired tokens.
 */
const jwt = require("jsonwebtoken");
const config = require("./config");

function signToken(payload) {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.expiresIn,
  });
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");
  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ error: "missing bearer token" });
  }
  try {
    req.auth = jwt.verify(token, config.jwt.secret);
    return next();
  } catch {
    return res.status(401).json({ error: "invalid or expired token" });
  }
}

/** Coarse role gate; use after requireAuth. */
function requireRole(role) {
  return (req, res, next) => {
    if (!req.auth || req.auth.role !== role) {
      return res.status(403).json({ error: "forbidden" });
    }
    return next();
  };
}

module.exports = { signToken, requireAuth, requireRole };
