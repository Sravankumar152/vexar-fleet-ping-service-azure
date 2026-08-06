"use strict";

/**
 * One-time-password issuance and verification.
 *
 * OTPs are random, short-lived and single-use. Only a salted scrypt HASH is
 * stored (never the plaintext), verification is constant-time, and attempts
 * are capped to resist brute force. This closes the original login flaw where
 * the `otp` field was accepted but never checked.
 *
 * NOTE: OTP *delivery* (SMS) is pluggable and out of scope here — in dev the
 * code is logged; in prod you would call an SMS provider.
 */
const crypto = require("crypto");
const { promisify } = require("util");
const config = require("./config");
const logger = require("./logger");

const scrypt = promisify(crypto.scrypt);

function generateNumericOtp(length) {
  const max = 10 ** length;
  const n = crypto.randomInt(0, max);
  return String(n).padStart(length, "0");
}

async function hash(otp, salt) {
  const derived = await scrypt(otp, salt, 32);
  return derived.toString("hex");
}

function safeEqualHex(a, b) {
  const ba = Buffer.from(a, "hex");
  const bb = Buffer.from(b, "hex");
  return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
}

/** Create and persist an OTP for a phone; returns the plaintext to deliver. */
async function issueOtp(db, phone) {
  const otp = generateNumericOtp(config.otp.length);
  const salt = crypto.randomBytes(16).toString("hex");
  const otpHash = `${salt}:${await hash(otp, salt)}`;
  const expiresAt = new Date(Date.now() + config.otp.ttlSeconds * 1000);

  await db.query(
    `INSERT INTO driver_otps (phone, otp_hash, expires_at) VALUES ($1, $2, $3)`,
    [phone, otpHash, expiresAt],
  );

  if (!config.isProd) {
    logger.info({ phone, otp }, "DEV OTP issued (would be sent via SMS)");
  }
  return otp;
}

/** Verify an OTP. Returns true on success and consumes it. */
async function verifyOtp(db, phone, otp) {
  const { rows } = await db.query(
    `SELECT id, otp_hash, expires_at, consumed_at, attempts
       FROM driver_otps
      WHERE phone = $1
      ORDER BY created_at DESC
      LIMIT 1`,
    [phone],
  );
  if (rows.length === 0) return false;

  const row = rows[0];
  if (row.consumed_at) return false;
  if (new Date(row.expires_at).getTime() < Date.now()) return false;
  if (row.attempts >= config.otp.maxAttempts) return false;

  const [salt, expected] = String(row.otp_hash).split(":");
  const candidate = await hash(otp, salt);
  const ok = safeEqualHex(candidate, expected);

  if (ok) {
    await db.query(
      `UPDATE driver_otps SET consumed_at = now() WHERE id = $1`,
      [row.id],
    );
  } else {
    await db.query(
      `UPDATE driver_otps SET attempts = attempts + 1 WHERE id = $1`,
      [row.id],
    );
  }
  return ok;
}

module.exports = { issueOtp, verifyOtp, generateNumericOtp };
