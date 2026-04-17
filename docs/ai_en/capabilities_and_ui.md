# Capabilities and UI integration

This project intentionally splits:

- **Control plane (typed)**: actuator targets are code-driven for safety (`water_valve` today).
- **Data plane (extensible)**: sensor readings and per-key timestamps are maps (`readings`, `readings_updated_at`).

## 1) Backend capability registry

Endpoint:

- `GET /devices/{deviceId}/capabilities`

Response fields:

- `actuators`: list of supported actuator targets (stable + curated)
- `sensors`: list of known sensor codes (from `sensor_types`)
- `settings_prefixes`: prefixes like `irrigation.` used to group settings in UIs

## 2) Flutter expectations

Dashboard:

- Shows a few fixed “core cards” (valve + a few primary sensors).
- “Last updated” should reflect humidity update time, not actuator actions.

Details page:

- Uses `/capabilities` + `/state` extensible maps to render additional sensors/outputs.
- Must treat unknown keys as informational (no hardcoded assumptions).

## 3) How to add a new sensor

High-level:

- Device publishes a new `readings.<sensor_code>` key in MQTT sensor payload.
- Backend records it (creates `sensor_types` row if missing) and exposes in `/state.readings`.
- `/capabilities.sensors` includes it once the backend has seen it.
- Flutter Details page should display it automatically; Dashboard only if explicitly added.

