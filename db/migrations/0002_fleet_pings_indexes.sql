-- 0002_fleet_pings_indexes: indexes for the hot read paths.
-- fleet_pings is append-heavy (every vehicle, frequently). The common queries
-- are "latest pings for a vehicle" and time-range scans, so index accordingly.

-- Latest-per-vehicle / per-vehicle history (composite, ts descending).
CREATE INDEX IF NOT EXISTS idx_fleet_pings_vehicle_ts
  ON fleet_pings (vehicle_id, ts DESC);

-- Time-range queries across the whole fleet (dashboards, exports).
CREATE INDEX IF NOT EXISTS idx_fleet_pings_ts
  ON fleet_pings (ts DESC);

-- Ingestion-lag / operational queries on arrival time.
CREATE INDEX IF NOT EXISTS idx_fleet_pings_created_at
  ON fleet_pings (created_at DESC);
