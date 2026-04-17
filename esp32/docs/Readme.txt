VuonRau ESP32 — build & upload
================================

USB (first flash):
  cd esp32 && pio run -e normal -t upload

OTA (espota; upload_port defaults to vuonrau-esp32.local — same name as MDNS_HOSTNAME in platformio.ini):
  pio run -e normal_ota -t upload
  pio run -e test_sensor_ota -t upload
  If upload cannot resolve .local, set upload_port to the IP printed as [ota] ready ip=...

Serial log after WiFi connects:
  [mdns] vuonrau-esp32.local   — resolver on LAN (mDNS + DHCP hostname)
  [ota] ready ip=192.168.x.x

If espota hangs on "Waiting for device", add your PC’s Wi‑Fi IP (same subnet), e.g. in test_sensor_ota:
  upload_flags =
    --timeout=60
    --host_ip=192.168.1.x

Modes
-----
  normal          — production (relay + MQTT heartbeat)
  test_sensor_ota — fast ADC + MQTT sensor (OTA only in this env; add USB env if needed)
