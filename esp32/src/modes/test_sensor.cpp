#include "test_sensor.h"
#include "../core/app_config.h"
#include "../core/mqtt_service.h"
#include "../core/sensor_adc.h"
#include <Arduino.h>

namespace {

const unsigned long SAMPLE_INTERVAL_MS = 1000UL;
const int ADC_SAMPLES = 32;

unsigned long lastSampleMs = 0;

void logAndPublishAdcBatch() {
  int minV = 4095;
  int maxV = 0;
  long sum = 0;

  for (int i = 0; i < ADC_SAMPLES; i++) {
    int v = analogRead(SENSOR_PIN);
    if (v < minV) {
      minV = v;
    }
    if (v > maxV) {
      maxV = v;
    }
    sum += v;
    delayMicroseconds(200);
  }

  int mean = static_cast<int>(sum / ADC_SAMPLES);
  float estV = (mean / 4095.0f) * 3.3f;

  Serial.printf("[test_sensor] ADC raw: mean=%d min=%d max=%d spread=%d est=%.3fV\n",
                mean,
                minV,
                maxV,
                maxV - minV,
                estV);

  MqttService::setHumidityRaw(mean);
  if (MqttService::isConnected()) {
    MqttService::publishSensor();
  } else {
    Serial.println(F("[test_sensor] mqtt offline, skip publish"));
  }
}

} // namespace

void setup_child() {
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  pinMode(SENSOR_PIN, INPUT);
  analogSetAttenuation(ADC_11db);

  Serial.println(F("=== test_sensor mode ==="));
  Serial.print(F("SENSOR_PIN="));
  Serial.println(SENSOR_PIN);
  Serial.print(F("DEVICE_ID="));
  Serial.println(DEVICE_ID);
  Serial.println(F("Publishing sensor JSON every 1s when MQTT connected."));
}

void loop_child() {
  unsigned long now = millis();
  if (now - lastSampleMs < SAMPLE_INTERVAL_MS) {
    return;
  }
  lastSampleMs = now;
  logAndPublishAdcBatch();
}
