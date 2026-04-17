Two firmware trees
====================

esp32/
  Canonical project: MODE=0 production + optional MODE=1 test_sensor; use esp32dev
  (or other boards) when WiFi and ADC1/ADC2 can run together.

esp32_cam/
  Temporary fork for AI Thinker ESP32-CAM only. ADC2 is not usable while the Wi‑Fi radio
  is on, so soil moisture sampling runs a short job: pause auto-reconnect, WiFi off,
  analog average, WiFi on, then MQTT reconnects on the next loops (see
  src/core/sensor_adc_wifi_suspend.cpp).

When you retire the CAM board, delete or ignore esp32_cam/ and build from esp32/ only.

Build (USB):  cd esp32_cam && pio run -e normal -t upload
OTA:          pio run -e normal_ota -t upload
