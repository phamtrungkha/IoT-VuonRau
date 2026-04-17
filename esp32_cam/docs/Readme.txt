VuonRau ESP32-CAM — build & upload
==================================

USB (first flash):
  cd esp32_cam && pio run -e normal -t upload

OTA (espota; upload_port defaults to vuonrau-esp32.local — same as MDNS_HOSTNAME):
  pio run -e normal_ota -t upload

Serial after WiFi connects:
  [mdns] vuonrau-esp32.local
  [ota] ready ip=192.168.x.x

Every heartbeat interval, firmware publishes state, then runs a WiFi-off soil ADC job
(non-blocking across loop iterations). When the job finishes you may see:
  [adc] WiFi restored after soil sample
or on failure:
  [adc] WiFi reconnect timeout after soil sample

See ../README.txt for how this tree relates to ../esp32/.
