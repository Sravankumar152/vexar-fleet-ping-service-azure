-- 0001_init: baseline schema for the Fleet Ping Service.
-- Tightened vs the original: NOT NULL constraints, sane defaults, timestamptz.

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
