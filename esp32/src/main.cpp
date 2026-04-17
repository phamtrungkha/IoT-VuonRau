#include <Arduino.h>
#include "core/app_config.h"
#include "core/mqtt_service.h"
#include "core/ota_mdns.h"
#include "core/wifi_manager.h"

/**
 * ESP32 water controller — firmware entry point.
 *
 * WiFi + MQTT + OTA live in core/. Mode-specific behavior is in modes/
 * and selected at compile time (MODE + build_src_filter in platformio.ini).
 */

#ifndef MODE
#define MODE 0
#endif

#if MODE == 0
#include "modes/production.h"
#elif MODE == 1
#include "modes/test_sensor.h"
#else
#error Unsupported MODE value
#endif

void setup() {
  Serial.begin(115200);
  WifiManager::begin();
  MqttService::setup();
  WifiManager::loop();
  MqttService::loop();
  setup_child();
}

static bool otaStarted = false;

void loop() {
  WifiManager::loop();
  if (WifiManager::isConnected() && !otaStarted) {
    OtaMdns::ensureStarted();
    otaStarted = true;
  }
  if (otaStarted) {
    OtaMdns::handle();
  }
  MqttService::loop();
  loop_child();
}
