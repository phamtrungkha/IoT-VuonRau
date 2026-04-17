-- Backfill new tables from legacy tables.
-- Safe to run multiple times (idempotent-ish) using INSERT IGNORE / upserts.

-- 1) Devices from any known legacy tables.
INSERT IGNORE INTO devices (id)
SELECT DISTINCT ds.device_id FROM device_settings ds
WHERE ds.device_id IS NOT NULL AND ds.device_id <> '';

INSERT IGNORE INTO devices (id)
SELECT DISTINCT sd.device_id FROM sensor_data sd
WHERE sd.device_id IS NOT NULL AND sd.device_id <> '';

INSERT IGNORE INTO devices (id)
SELECT DISTINCT il.device_id FROM irrigation_log il
WHERE il.device_id IS NOT NULL AND il.device_id <> '';

-- 2) Seed sensor types we know today.
INSERT INTO sensor_types (code, value_type, unit)
VALUES ('humidity_raw', 'int', 'raw')
ON DUPLICATE KEY UPDATE code = code;

-- 3) Backfill settings KV using namespaced keys.
INSERT INTO device_settings_kv (device_id, setting_key, value_type, value_int, updated_at)
SELECT
  ds.device_id,
  'irrigation.auto_off_seconds' AS setting_key,
  'int' AS value_type,
  ds.auto_off_seconds AS value_int,
  ds.updated_at
FROM device_settings ds
ON DUPLICATE KEY UPDATE
  value_type = VALUES(value_type),
  value_int = VALUES(value_int),
  updated_at = VALUES(updated_at);

INSERT INTO device_settings_kv (device_id, setting_key, value_type, value_int, updated_at)
SELECT
  ds.device_id,
  'irrigation.moisture_threshold_raw' AS setting_key,
  'int' AS value_type,
  ds.moisture_threshold_raw AS value_int,
  ds.updated_at
FROM device_settings ds
ON DUPLICATE KEY UPDATE
  value_type = VALUES(value_type),
  value_int = VALUES(value_int),
  updated_at = VALUES(updated_at);

-- 4) Backfill sensor readings (humidity_raw only today).
INSERT INTO sensor_readings (device_id, sensor_type_id, value_int, captured_at, ingested_at)
SELECT
  sd.device_id,
  st.id AS sensor_type_id,
  sd.humidity_raw AS value_int,
  sd.created_at AS captured_at,
  sd.created_at AS ingested_at
FROM sensor_data sd
JOIN sensor_types st ON st.code = 'humidity_raw'
LEFT JOIN sensor_readings sr
  ON sr.device_id = sd.device_id
 AND sr.sensor_type_id = st.id
 AND sr.captured_at = sd.created_at
 AND sr.value_int = sd.humidity_raw
WHERE sr.id IS NULL;

