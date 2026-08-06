"use strict";

/**
 * Structured JSON logging via pino. Emits one JSON object per line — exactly
 * what Container Insights / Log Analytics ingests. Sensitive fields are
 * redacted so tokens, passwords and OTPs never reach the logs.
 */
const pino = require("pino");
const config = require("./config");

const logger = pino({
  level: config.logLevel,
  redact: {
    paths: [
      "req.headers.authorization",
      "req.headers.cookie",
      "*.password",
      "*.otp",
      "*.token",
      "*.jwt",
    ],
    censor: "[REDACTED]",
  },
  base: { service: "fleet-ping-service", env: config.env },
  timestamp: pino.stdTimeFunctions.isoTime,
});

module.exports = logger;
