"use strict";

/**
 * Request validation schemas (zod). Every external input is validated and
 * coerced before it reaches the database layer.
 */
const { z } = require("zod");

// E.164-ish phone: optional leading +, 7-15 digits.
const phone = z
  .string()
  .trim()
  .regex(/^\+?[0-9]{7,15}$/, "invalid phone number");

const requestOtpSchema = z.object({
  phone,
});

const loginSchema = z.object({
  phone,
  otp: z
    .string()
    .trim()
    .regex(/^[0-9]{4,8}$/, "invalid otp"),
});

const pingSchema = z.object({
  vehicleId: z.string().trim().min(1).max(50),
  lat: z.coerce.number().gte(-90).lte(90),
  lng: z.coerce.number().gte(-180).lte(180),
  speed: z.coerce.number().gte(0).lte(500).optional(),
  timestamp: z.coerce.date().optional(),
});

/** Express helper: validate req.body against a schema or 400. */
function validateBody(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        error: "validation failed",
        details: result.error.issues.map((i) => ({
          path: i.path.join("."),
          message: i.message,
        })),
      });
    }
    req.validated = result.data;
    return next();
  };
}

module.exports = { requestOtpSchema, loginSchema, pingSchema, validateBody };
