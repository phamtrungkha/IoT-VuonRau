-- Make legacy->new backfill safe and MySQL 8.0 friendly.
-- This migration is safe to run even if V2 already populated data.

-- 1) Devices: use a single INSERT IGNORE with UNION to avoid duplicate-key errors.
INSERT IGNORE INTO devices (id)
SELECT device_id FROM (
  SELECT DISTINCT ds.device_id AS device_id FROM device_settings ds
  UNION
  SELECT DISTINCT sd.device_id AS device_id FROM sensor_data sd
  UNION
  SELECT DISTINCT il.device_id AS device_id FROM irrigation_log il
) u
WHERE u.device_id IS NOT NULL AND u.device_id <> '';

