# MQTT Contract (Device Control)

This is the **canonical** MQTT contract used by:

- ESP32 firmware (device)
- Backend (REST ↔ MQTT bridge)

Flutter MUST NOT use MQTT directly.

## 1) Topics

All topics are scoped by `device_id`.

- Request (Backend → Device): `device/{device_id}/request`
- Response (Device → Backend): `device/{device_id}/response`
- Status (Device → Broker, retained LWT/online): `device/{device_id}/status`

Example for `device_id = water_controller`:

- `device/water_controller/request`
- `device/water_controller/response`
- `device/water_controller/status`

## 2) Correlation

`request_id` is OPTIONAL but recommended.

- If present in a request, the device SHOULD echo it in its response (`ack` and optionally `state`).
- Backend SHOULD treat responses without `request_id` as **un-correlated** telemetry/state.

## 3) Request payloads (Backend → Device)

### 3.1 Set actuator (generic)

```json
{
  "device": "water_controller",
  "action": "set",
  "target": "water_valve",
  "value": true,
  "request_id": "string"
}
```

Rules:

- `device` (string, required): device id
- `action` (string, required): currently `set`
- `target` (string, required): capability name, e.g. `water_valve`
- `value` (required for relay targets): boolean
- `request_id` (string, optional): correlation id

### 3.2 Config patch (optional)

If the backend needs to push runtime config to the device, it SHOULD use `config_patch` with namespaced keys.

```json
{
  "device": "water_controller",
  "action": "config_patch",
  "patch": [
    { "key": "irrigation.auto_off_seconds", "type": "int", "value": 40 },
    { "key": "irrigation.moisture_threshold_raw", "type": "int", "value": 3000 }
  ],
  "request_id": "string"
}
```

Forward-compatibility rules:

- Device MUST ignore unknown keys.
- Keys SHOULD be namespaced: `<domain>.<name>` (e.g. `irrigation.*`, `fan.*`).

## 4) Response payloads (Device → Backend)

The device may publish either an `ack`, a `state`, a `sensor`, or a combination.

### 4.1 Sensor payload (heartbeat)

```json
{
  "device": "water_controller",
  "type": "sensor",
  "readings": {
    "humidity_raw": 1234
  },
  "timestamp": 12345
}
```

- `readings` (object): map of `sensor_code -> value` for one or more sensors.
- `timestamp` (int): **device uptime seconds** (seconds since boot).

Invariants:

- `sensor_code` MUST be stable identifiers (e.g. `humidity_raw`, `temperature_c`, `light_lux`).
- Devices MAY add new reading keys over time.
- Backend MUST ignore unknown keys (forward-compatible).

### 4.2 ACK response

```json
{
  "device": "water_controller",
  "type": "ack",
  "target": "water_valve",
  "value": true,
  "ok": true,
  "request_id": "string",
  "timestamp": 12345
}
```

Rules:

- For `ok=false`, device SHOULD provide `error` (string) if possible.
- For unknown `target`, device SHOULD publish `ok=false` with `error:"unknown_target"`.

### 4.3 State snapshot response

```json
{
  "device": "water_controller",
  "type": "state",
  "water_valve": true,
  "timestamp": 12345,
  "request_id": "string"
}
```

Notes:

- `timestamp` is **device uptime seconds** (not Unix time).
- `request_id` MAY be included when `state` is emitted as a direct result of handling a request.

## 5) Backward-compatibility policy

This contract is designed to be forward-compatible via:

- ignoring unknown `target` (device returns a NACK)
- ignoring unknown keys under `readings`

Avoid breaking changes (renaming keys) once deployed.

