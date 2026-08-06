"use strict";

const express = require("express");
const { signToken } = require("../auth");
const { issueOtp, verifyOtp } = require("../otp");
const {
  validateBody,
  requestOtpSchema,
  loginSchema,
} = require("../validation");

module.exports = function authRoutes({ db }) {
  const router = express.Router();

  // Step 1: request an OTP for a phone number.
  router.post(
    "/request-otp",
    validateBody(requestOtpSchema),
    async (req, res, next) => {
      try {
        await issueOtp(db, req.validated.phone);
        // 202 + generic body: don't reveal whether the number is registered.
        res.status(202).json({ status: "otp sent if the number is valid" });
      } catch (err) {
        next(err);
      }
    },
  );

  // Step 2: exchange phone + OTP for a JWT.
  // Fixes the original SQL injection (string-built query) AND the auth bypass
  // (OTP was never verified).
  router.post("/login", validateBody(loginSchema), async (req, res, next) => {
    try {
      const { phone, otp } = req.validated;

      const otpOk = await verifyOtp(db, phone, otp);
      if (!otpOk) {
        return res.status(401).json({ error: "invalid credentials" });
      }

      const { rows } = await db.query(
        "SELECT id FROM drivers WHERE phone = $1",
        [phone],
      );
      if (rows.length === 0) {
        return res.status(401).json({ error: "invalid credentials" });
      }

      const token = signToken({ driverId: rows[0].id, role: "driver" });
      return res.json({ token });
    } catch (err) {
      return next(err);
    }
  });

  return router;
};
