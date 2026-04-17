#include <Arduino.h>
#include "core/app_config.h"
#include "core/mqtt_service.h"
#include "core/ota_mdns.h"
#include "core/wifi_manager.h"
#include "modes/production.h"

/**
 * ESP32-CAM water controller — same core as esp32/, production only (no test_sensor mode).
 */

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
