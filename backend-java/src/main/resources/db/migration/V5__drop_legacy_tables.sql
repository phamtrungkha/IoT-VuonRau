-- Go-live cleanup: drop legacy tables after KV + sensor_readings migration.
--
-- Notes:
-- - We intentionally KEEP `irrigation_log` because it is still used by the backend.
-- - Use IF EXISTS so this is safe across environments.

DROP TABLE IF EXISTS sensor_data;
DROP TABLE IF EXISTS device_settings;

