# REST API Contract (Flutter ↔ Backend)

Base URL example: `http://<BACKEND_IP>:8000`

## 1) Device ID allowlist

Backend rejects unknown devices (for safety). Device id is validated against backend config.

## 2) Endpoints

### 2.1 Execute action

`POST /devices/{deviceId}/actions`

Request body:

```json
{
  "target": "water_valve",
  "value": true
}
```

Responses:

- `200 OK` (action completed quickly)

```json
{
  "status": "ok",
  "request_id": "string",
  "mqtt": {
    "device": "water_controller",
    "type": "ack",
    "target": "water_valve",
    "value": true,
    "ok": true,
    "timestamp": 12345,
    "request_id": "string"
  }
}
```

- `202 Accepted` (backend timed out waiting for device response)

```json
{
  "status": "accepted",
  "request_id": "string"
}
```

Client rule (Flutter):

- ALWAYS re-fetch state after actions; never assume success.

### 2.2 Get device state (stable + extensible)

`GET /devices/{deviceId}/state`

Returns:

- **stable fields** (dashboard): `water_valve`, `humidity_raw`, `humidity_updated_at`, `timestamp`, `updated_at`, `stale`, `last_request_id`
- **extensible maps** (details page): `readings`, `readings_updated_at`, `outputs`

Example:

```json
{
  "device": "water_controller",
  "water_valve": true,
  "humidity_raw": 1234,
  "humidity_updated_at": 1710000000.0,
  "readings": {
    "humidity_raw": 1234,
    "temperature_c": 29.4
  },
  "readings_updated_at": {
    "humidity_raw": 1710000000.0,
    "temperature_c": 1710000000.0
  },
  "outputs": {
    "water_valve": true
  },
  "timestamp": 12345,
  "updated_at": 1710000001.0,
  "stale": false,
  "last_request_id": "string"
}
```

Semantics:

- `timestamp`: device uptime seconds (from ESP32 MQTT payloads)
- `updated_at`: backend wall-clock time when it updated in-memory state
- `humidity_updated_at`: backend wall-clock time when humidity reading last changed (NOT affected by actuator actions)
- `readings_updated_at`: per-reading timestamps (backend wall-clock)

### 2.3 Capability registry

`GET /devices/{deviceId}/capabilities`

Example:

```json
{
  "device_id": "water_controller",
  "actuators": ["water_valve"],
  "sensors": ["humidity_raw"],
  "settings_prefixes": ["irrigation."]
}
```

### 2.4 Device settings (KV)

`GET /devices/{deviceId}/settings`

Example:

```json
{
  "device_id": "water_controller",
  "settings": [
    {
      "key": "irrigation.auto_off_seconds",
      "type": "int",
      "value": 30,
      "updated_at": 1710000000.0
    }
  ]
}
```

`PUT /devices/{deviceId}/settings`

Request body:

```json
{
  "patch": [
    { "key": "irrigation.auto_off_seconds", "type": "int", "value": 40 }
  ]
}
```

### 2.5 Settings definitions (metadata)

`GET /settings/definitions`

Returns a static list of supported settings definitions (type, default, min/max, UI hints).

## 3) Error handling (high-level)

- If MQTT is disconnected, action may fail (backend may return 503 via exception handler).
- Device not reporting → state becomes `stale=true`.

