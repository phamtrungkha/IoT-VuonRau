#include "production.h"
#include "../core/app_config.h"
#include "../core/mqtt_service.h"
#include "../core/sensor_adc.h"
#include <Arduino.h>

namespace {

const unsigned long HEARTBEAT_INTERVAL_MS = 5UL * 60UL * 1000UL;
unsigned long lastHeartbeatMs = 0;

} // namespace

void setup_child() {
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  pinMode(SENSOR_PIN, INPUT);
  analogSetAttenuation(ADC_11db);
}

void loop_child() {
  unsigned long now = millis();
  if (now - lastHeartbeatMs < HEARTBEAT_INTERVAL_MS) {
    return;
  }
  lastHeartbeatMs = now;

  MqttService::publishState(nullptr);
  int raw = readAdcAvg(SENSOR_PIN, 10, 200);
  MqttService::setHumidityRaw(raw);
  MqttService::publishSensor();
}
