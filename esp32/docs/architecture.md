# ESP32 firmware layout

## ESP32-CAM fork (`esp32_cam/`)

For **AI Thinker ESP32-CAM** only (ADC2 blocked while Wi‑Fi is on), use the parallel project [`../esp32_cam/README.txt`](../esp32_cam/README.txt): same MQTT/valve behaviour, production-only, with **WiFi suspended during soil ADC** (`esp32_cam/src/core/sensor_adc_wifi_suspend.cpp`). Long-term / devkit builds stay in this `esp32/` tree.

## Entry

- [`src/main.cpp`](../src/main.cpp) — `setup` / `loop`: WiFi, MQTT, OTA+mDNS, then mode hooks `setup_child` / `loop_child`.

## Core (`src/core/`)

| File | Role |
|------|------|
| `app_config.h` | Build-time macros (`DEVICE_ID`, pins, WiFi/MQTT); override via `platformio.ini`. |
| `wifi_manager.cpp` | STA, reconnect, `WiFi.setHostname`. |
| `mqtt_service.cpp` | PubSub client, topics `device/<id>/{request,response,status}`, valve commands. |
| `ota_mdns.cpp` | `ESPmDNS` + `ArduinoOTA` after WiFi is up. |
| `sensor_adc.h` | `readAdcAvg()` helper. |

## Modes (`src/modes/`)

Selected by **`-DMODE`** + `build_src_filter` in [`platformio.ini`](../platformio.ini):

- **MODE=0** — `production.cpp`: relay + soil ADC on heartbeat interval.
- **MODE=1** — `test_sensor.cpp`: ADC logging + MQTT sensor at 1 s.

## MQTT command (production)

```json
{"device":"water_controller","target":"water_valve","action":"set","value":true}
```

Optional `request_id` is echoed in `state` / `ack` payloads.
