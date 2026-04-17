# DB schema and Flyway migrations (MySQL)

Backend: `backend-java/` (Spring Boot + JPA + Flyway)

## 1) Tables (scale-ready)

Core tables:

- `devices`: known device ids
- `device_settings_kv`: device settings as namespaced key-value rows
- `sensor_types`: registry of sensor codes (e.g. `humidity_raw`)
- `sensor_readings`: time-series readings per device + sensor type
- `irrigation_log`: action log (kept; still used)

### 1.1 `device_settings_kv` typing model

`value_type` is a string enum (portability):

- `int`, `double`, `bool`, `string`, `json`

Storage columns:

- `value_int` (also used for `bool` as 0/1)
- `value_double`
- `value_string`
- `value_json` (string/JSON depending on DB)

## 2) Flyway migrations

Migrations live in:

- `backend-java/src/main/resources/db/migration/`

### V1 — create scalable tables

- `V1__create_scalable_tables.sql`
- Creates: `devices`, `device_settings_kv`, `sensor_types`, `sensor_readings`

### V2 — backfill from legacy tables (optional / transitional)

- `V2__backfill_from_legacy_tables.sql`
- Reads legacy tables: `device_settings`, `sensor_data`, `irrigation_log`
- Populates new tables (idempotent-ish)

### V3 — idempotent device backfill (mysql8 compat)

- `V3__backfill_idempotent_and_mysql8_compat.sql`
- Ensures `devices` insert is idempotent using UNION

### V4 — portability: ENUM → VARCHAR

- `V4__value_type_enum_to_varchar.sql`
- Alters `value_type` columns to `VARCHAR(16)` for easier portability/testing

### V5 — go-live cleanup: drop legacy tables

- `V5__drop_legacy_tables.sql`
- Drops (if exists):
  - `device_settings`
  - `sensor_data`
- Intentionally keeps `irrigation_log`

## 3) Go-live notes

- After V5, legacy tables are removed; rollbacks must rely on backups, not legacy tables.
- For safety, ensure any required data is already in:
  - `device_settings_kv`
  - `sensor_readings`

