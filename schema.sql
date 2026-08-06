-- ============================================================================
-- Full-schema snapshot (convenience for local bootstrapping).
-- The AUTHORITATIVE source of truth is db/migrations/*.sql — apply those with
-- `npm run db:migrate`. Keep this snapshot in sync if you regenerate it.
-- ============================================================================

CREATE TABLE IF NOT EXISTS drivers (
  id         BIGSERIAL PRIMARY KEY,
  phone      VARCHAR(20) UNIQUE NOT NULL,
  name       VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fleet_pings (
  id         BIGSERIAL PRIMARY KEY,
  vehicle_id VARCHAR(50)   NOT NULL,
  lat        DECIMAL(9, 6) NOT NULL,
  lng        DECIMAL(9, 6) NOT NULL,
  speed      DECIMAL(5, 2),
  ts         TIMESTAMPTZ   NOT NULL,
  created_at TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fleet_pings_vehicle_ts ON fleet_pings (vehicle_id, ts DESC);
CREATE INDEX IF NOT EXISTS idx_fleet_pings_ts ON fleet_pings (ts DESC);
CREATE INDEX IF NOT EXISTS idx_fleet_pings_created_at ON fleet_pings (created_at DESC);

CREATE TABLE IF NOT EXISTS driver_otps (
  id          BIGSERIAL PRIMARY KEY,
  phone       VARCHAR(20) NOT NULL,
  otp_hash    TEXT        NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  attempts    INT         NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_driver_otps_phone_created ON driver_otps (phone, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_driver_otps_expires_at ON driver_otps (expires_at);
