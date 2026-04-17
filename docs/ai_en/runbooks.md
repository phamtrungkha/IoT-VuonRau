# Runbooks (ops cheatsheet)

## 1) Observe MQTT traffic

```bash
mosquitto_sub -h 127.0.0.1 -p 1883 -v -t "device/water_controller/#"
```

## 2) Backend health checks

```bash
curl -sS "http://127.0.0.1:8000/devices/water_controller/state"
curl -sS "http://127.0.0.1:8000/devices/water_controller/capabilities"
curl -sS "http://127.0.0.1:8000/devices/water_controller/settings"
```

## 3) Common failure modes

### Backend returns 503 on actions

Likely: MQTT broker unreachable / backend not connected.

Check:

- Mosquitto running: `sudo systemctl status mosquitto`
- Backend logs: `sudo journalctl -u vuonrau-backend -f`

### Device state is stale

Likely: device not publishing `state`/`sensor`.

Check:

- MQTT subscriber output (see 1)
- ESP32 Wi‑Fi credentials and `MQTT_HOST`/`MQTT_PORT`

