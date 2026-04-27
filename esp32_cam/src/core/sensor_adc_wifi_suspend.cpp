#include "sensor_adc_wifi_suspend.h"
#include "app_config.h"
#include "sensor_adc.h"
#include "wifi_manager.h"
#include <Arduino.h>
#include <WiFi.h>

namespace {

enum class Phase { Idle, WifiOff, Settle, Sample, WaitConn };

Phase phase = Phase::Idle;
int pendingPin = 0;
int pendingSamples = 0;
unsigned int pendingDelayUs = 0;
int resultRaw = -1;
unsigned long phaseStartMs = 0;

const unsigned long SETTLE_MS = 150;
const unsigned long WIFI_CONNECT_TIMEOUT_MS = 30000;
/** Short delay after restoring STA mode so the RF stack is ready before WiFi.begin (reduces flaky reconnect). */
const unsigned long WIFI_STA_SETTLE_MS = 80;

} // namespace

void soilAdcWifiSuspendJobStart(int pin, int samples, unsigned int delayUs) {
  if (phase != Phase::Idle) {
    return;
  }
  pendingPin = pin;
  pendingSamples = samples;
  pendingDelayUs = delayUs;
  resultRaw = -1;
  phase = Phase::WifiOff;
  WifiManager::setReconnectPaused(true);
}

bool soilAdcWifiSuspendJobIsActive() { return phase != Phase::Idle; }

bool soilAdcWifiSuspendJobPoll(int *outRaw) {
  if (phase == Phase::Idle || outRaw == nullptr) {
    return false;
  }

  const unsigned long now = millis();

  switch (phase) {
  case Phase::Idle:
    return false;

  case Phase::WifiOff:
    // RF off only: avoid aggressive disconnect paths that can leave STA/NVS in odd states after many cycles.
    WiFi.mode(WIFI_OFF);
    phase = Phase::Settle;
    phaseStartMs = now;
    return false;

  case Phase::Settle:
    if (now - phaseStartMs < SETTLE_MS) {
      return false;
    }
    phase = Phase::Sample;
    return false;

  case Phase::Sample:
    resultRaw = readAdcAvg(pendingPin, pendingSamples, pendingDelayUs);
    WiFi.mode(WIFI_STA);
    delay(WIFI_STA_SETTLE_MS);
    WiFi.persistent(false);
    WiFi.setHostname(MDNS_HOSTNAME);
    WiFi.setAutoReconnect(true);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    phase = Phase::WaitConn;
    phaseStartMs = millis();
    return false;

  case Phase::WaitConn:
    if (WiFi.status() == WL_CONNECTED) {
      *outRaw = resultRaw;
      phase = Phase::Idle;
      WifiManager::afterAdcSuspendCycle(true);
      WifiManager::setReconnectPaused(false);
      Serial.println(F("[adc] WiFi restored after soil sample"));
      return true;
    }
    if (now - phaseStartMs >= WIFI_CONNECT_TIMEOUT_MS) {
      *outRaw = -1;
      phase = Phase::Idle;
      WifiManager::afterAdcSuspendCycle(false);
      WifiManager::setReconnectPaused(false);
      Serial.println(F("[adc] WiFi reconnect timeout after soil sample"));
      return true;
    }
    return false;
  }

  return false;
}
