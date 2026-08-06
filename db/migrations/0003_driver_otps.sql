-- 0003_driver_otps: storage for login OTPs.
-- The original login accepted an `otp` field but never verified it (auth
-- bypass). OTPs are stored HASHED with a short expiry and single-use semantics.

CREATE TABLE IF NOT EXISTS driver_otps (
  id          BIGSERIAL PRIMARY KEY,
  phone       VARCHAR(20) NOT NULL,
  otp_hash    TEXT        NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  attempts    INT         NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Look up the newest unexpired OTP for a phone number quickly.
CREATE INDEX IF NOT EXISTS idx_driver_otps_phone_created
  ON driver_otps (phone, created_at DESC);

-- Supports a scheduled cleanup job that purges expired rows.
CREATE INDEX IF NOT EXISTS idx_driver_otps_expires_at
  ON driver_otps (expires_at);
