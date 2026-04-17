# VuonRau (Flutter app)

Flutter client for VuonRau IoT system.

- REST only (no MQTT)
- Control: water valve ON/OFF
- Read latest device state from backend

## Getting Started

### 1) Prerequisites

- Flutter SDK installed
- VuonRau backend running on your LAN

### 2) Run

```bash
flutter pub get
flutter run
```

### 3) Configure backend base URL

In the app screen, set **Backend base URL**, for example:

- `http://192.168.1.10:8000`

Then press refresh.

### 4) API used

- `GET /devices/{device_id}/state`
- `POST /devices/{device_id}/actions` body: `{ "target": "water_valve", "value": true|false }`

### 5) Timestamp note

`timestamp` shown in the UI is **ESP32 uptime seconds** (seconds since ESP32 boot), not Unix time.
For “last seen”, use the backend-provided `updated_at`.
