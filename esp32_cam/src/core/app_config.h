#pragma once

/**
 * Build-time defaults — override in platformio.ini `build_flags`.
 * Prefer not committing real WiFi/MQTT secrets; keep them in env or a local overlay ini.
 */

#ifndef DEVICE_ID
#define DEVICE_ID "water_controller"
#endif

#ifndef RELAY_PIN
#define RELAY_PIN 15
#endif

#ifndef SENSOR_PIN
#define SENSOR_PIN 14
#endif

#ifndef WIFI_SSID
#define WIFI_SSID "YOUR_WIFI_SSID"
#endif

#ifndef WIFI_PASSWORD
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"
#endif

#ifndef MQTT_HOST
#define MQTT_HOST "192.168.1.1"
#endif

#ifndef MQTT_PORT
#define MQTT_PORT 1883
#endif

/**
 * Auto-off failsafe for watering valve (minutes). Set to 0 to disable.
 * Override in platformio.ini `build_flags`.
 */
#ifndef AUTO_OFF_MINUTES
#define AUTO_OFF_MINUTES 0
#endif

#define AUTO_OFF_TIMEOUT_MS (AUTO_OFF_MINUTES * 60UL * 1000UL)

/** DHCP hostname, ArduinoOTA hostname, and mDNS instance name (`<name>.local`). */
#ifndef MDNS_HOSTNAME
#define MDNS_HOSTNAME "vuonrau-esp32"
#endif
