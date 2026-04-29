-- Append-only valve state history (MQTT + manual). irrigation_log unchanged.

CREATE TABLE IF NOT EXISTS water_valve_events (
  id BIGINT NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(128) NOT NULL,
  on_state TINYINT(1) NOT NULL COMMENT '1=ON open, 0=OFF closed',
  source VARCHAR(32) NOT NULL,
  recorded_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_water_valve_events_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
  INDEX idx_water_valve_events_device_recorded (device_id, recorded_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backfill manual actions from legacy irrigation_log (idempotent by NOT EXISTS)
INSERT INTO water_valve_events (device_id, on_state, source, recorded_at)
SELECT
  il.device_id,
  CASE UPPER(TRIM(il.action)) WHEN 'ON' THEN 1 ELSE 0 END AS on_state,
  'manual' AS source,
  il.created_at AS recorded_at
FROM irrigation_log il
INNER JOIN devices d ON d.id = il.device_id
WHERE NOT EXISTS (
  SELECT 1 FROM water_valve_events w
  WHERE w.device_id = il.device_id
    AND w.source = 'manual'
    AND w.recorded_at = il.created_at
    AND w.on_state = CASE UPPER(TRIM(il.action)) WHEN 'ON' THEN 1 ELSE 0 END
);
