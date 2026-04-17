#include "ota_mdns.h"
#include "app_config.h"
#include <Arduino.h>
#include <ArduinoOTA.h>
#include <ESPmDNS.h>
#include <WiFi.h>

namespace {

bool gStarted = false;

} // namespace

namespace OtaMdns {

void ensureStarted() {
  if (gStarted) {
    return;
  }
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  if (!MDNS.begin(MDNS_HOSTNAME)) {
    Serial.println(F("[mdns] begin failed (OTA by IP still works)"));
  } else {
    Serial.print(F("[mdns] "));
    Serial.print(MDNS_HOSTNAME);
    Serial.println(F(".local"));
  }

  ArduinoOTA.setHostname(MDNS_HOSTNAME);
#ifdef OTA_PASSWORD
  ArduinoOTA.setPassword(OTA_PASSWORD);
#endif

  ArduinoOTA.onStart([]() {
    if (ArduinoOTA.getCommand() == U_FLASH) {
      Serial.println(F("[ota] start sketch"));
    } else {
      Serial.println(F("[ota] start filesystem"));
    }
  });
  ArduinoOTA.onEnd([]() { Serial.println(F("[ota] end")); });
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    static unsigned int lastPct = 0;
    unsigned int pct = (total > 0) ? (progress * 100 / total) : 0;
    if (pct >= lastPct + 10 || pct == 100) {
      lastPct = pct;
      Serial.printf("[ota] progress %u%%\n", pct);
    }
  });
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.printf("[ota] error=%u\n", static_cast<unsigned>(error));
  });

  ArduinoOTA.begin();
  gStarted = true;
  Serial.print(F("[ota] ready ip="));
  Serial.println(WiFi.localIP());
}

void handle() {
  if (!gStarted) {
    return;
  }
  ArduinoOTA.handle();
}

} // namespace OtaMdns
