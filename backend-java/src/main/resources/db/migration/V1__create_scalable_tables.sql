-- New scalable schema (non-destructive): settings KV + typed sensor readings.
-- Keep legacy tables (`device_settings`, `sensor_data`, `irrigation_log`) for backfill + rollback.

CREATE TABLE IF NOT EXISTS devices (
  id VARCHAR(128) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS device_settings_kv (
  device_id VARCHAR(128) NOT NULL,
  setting_key VARCHAR(128) NOT NULL,
  value_type ENUM('int','double','bool','string','json') NOT NULL,
  value_int BIGINT NULL,
  value_double DOUBLE NULL,
  value_string TEXT NULL,
  value_json JSON NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (device_id, setting_key),
  CONSTRAINT fk_device_settings_kv_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
  INDEX idx_device_settings_kv_key (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sensor_types (
  id BIGINT NOT NULL AUTO_INCREMENT,
  code VARCHAR(64) NOT NULL,
  value_type ENUM('int','double','bool','string','json') NOT NULL,
  unit VARCHAR(32) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uq_sensor_types_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sensor_readings (
  id BIGINT NOT NULL AUTO_INCREMENT,
  device_id VARCHAR(128) NOT NULL,
  sensor_type_id BIGINT NOT NULL,
  value_int BIGINT NULL,
  value_double DOUBLE NULL,
  value_string TEXT NULL,
  value_json JSON NULL,
  captured_at DATETIME(6) NOT NULL,
  ingested_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  CONSTRAINT fk_sensor_readings_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
  CONSTRAINT fk_sensor_readings_type FOREIGN KEY (sensor_type_id) REFERENCES sensor_types(id) ON DELETE RESTRICT,
  INDEX idx_sensor_readings_query (device_id, sensor_type_id, captured_at),
  INDEX idx_sensor_readings_captured_at (captured_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

