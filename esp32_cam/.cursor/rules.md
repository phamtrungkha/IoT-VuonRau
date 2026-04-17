# ESP32-CAM Rules (esp32_cam/)

## Context

* Read `docs/Readme.txt` and `../esp32/docs/architecture.md` for shared MQTT/WiFi layout.
* This tree is **ESP32-CAM only**; canonical multi-board firmware is `../esp32/`.

---

## Core Principles

* Do NOT overwrite behaviour in `../esp32/` from here unless intentionally syncing copies.
* Extend with small, focused modules (e.g. soil ADC WiFi suspend).

---

## MQTT

* Same topics as `esp32/`: `device/{device_id}/request` / `response` / `status`.

---

## Loop Behaviour

* `loop()` must stay non-blocking; soil sampling uses a phased job in
  `sensor_adc_wifi_suspend.cpp`, not long `delay()` in one tick.

---

## Sensor

* Soil ADC runs with WiFi off on this board; `WifiManager::setReconnectPaused` prevents
  fighting reconnect during the job.
