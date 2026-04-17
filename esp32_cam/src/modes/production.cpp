#include "production.h"
#include "../core/app_config.h"
#include "../core/mqtt_service.h"
#include "../core/sensor_adc_wifi_suspend.h"
#include <Arduino.h>

namespace {

const unsigned long HEARTBEAT_INTERVAL_MS = 5UL * 60UL * 1000UL;
unsigned long lastHeartbeatMs = 0;

/** MQTT publish after soil job: TCP must be re-opened after WiFi off/on (see MqttService::reconnectTransportAfterWifiSuspend). */
bool pendingSensorPublish = false;
unsigned long pendingSensorSinceMs = 0;
const unsigned long PENDING_SENSOR_GIVEUP_MS = 120UL * 1000UL;

} // namespace

void setup_child() {
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  pinMode(SENSOR_PIN, INPUT);
  analogSetAttenuation(ADC_11db);
}

void loop_child() {
  int raw = 0;

  if (pendingSensorPublish) {
    if (MqttService::isConnected()) {
      MqttService::publishSensor();
      pendingSensorPublish = false;
    } else if (millis() - pendingSensorSinceMs > PENDING_SENSOR_GIVEUP_MS) {
      Serial.println(F("[prod] sensor MQTT publish skipped (no broker after WiFi resume)"));
      pendingSensorPublish = false;
    }
  }

  if (soilAdcWifiSuspendJobIsActive()) {
    if (soilAdcWifiSuspendJobPoll(&raw)) {
      MqttService::setHumidityRaw(raw);
      MqttService::reconnectTransportAfterWifiSuspend();
      pendingSensorPublish = true;
      pendingSensorSinceMs = millis();
    }
    return;
  }

  unsigned long now = millis();
  if (now - lastHeartbeatMs < HEARTBEAT_INTERVAL_MS) {
    return;
  }
  if (pendingSensorPublish) {
    return;
  }
  lastHeartbeatMs = now;

  MqttService::publishState(nullptr);
  soilAdcWifiSuspendJobStart(SENSOR_PIN, 10, 200);
}
