-- Portability: prefer VARCHAR over ENUM for value_type columns.
-- This reduces coupling to MySQL-specific ENUM and makes JPA/H2 testing simpler.

ALTER TABLE device_settings_kv MODIFY value_type VARCHAR(16) NOT NULL;
ALTER TABLE sensor_types MODIFY value_type VARCHAR(16) NOT NULL;

