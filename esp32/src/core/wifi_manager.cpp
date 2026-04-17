#include "wifi_manager.h"
#include "app_config.h"
#include <WiFi.h>

namespace {

const unsigned long WIFI_RETRY_INTERVAL_MS = 10UL * 1000UL;
const unsigned long WIFI_HARD_RESET_AFTER_MS = 2UL * 60UL * 1000UL;

unsigned long lastWifiAttemptMs = 0;
unsigned long wifiDisconnectedSinceMs = 0;
unsigned long lastWifiHardResetMs = 0;

void ensureWifi() {
  if (WiFi.status() == WL_CONNECTED) {
    wifiDisconnectedSinceMs = 0;
    return;
  }

  unsigned long now = millis();
  if (wifiDisconnectedSinceMs == 0) {
    wifiDisconnectedSinceMs = now;
  }

  if (now - lastWifiAttemptMs < WIFI_RETRY_INTERVAL_MS) {
    return;
  }
  lastWifiAttemptMs = now;

  bool shouldHardReset = (now - wifiDisconnectedSinceMs >= WIFI_HARD_RESET_AFTER_MS) &&
                         (now - lastWifiHardResetMs >= WIFI_HARD_RESET_AFTER_MS);

  if (shouldHardReset) {
    lastWifiHardResetMs = now;
    WiFi.disconnect(true);
    WiFi.mode(WIFI_STA);
  }

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

} // namespace

namespace WifiManager {

void begin() {
  WiFi.mode(WIFI_STA);
  WiFi.setHostname(MDNS_HOSTNAME);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(false);
  ensureWifi();
}

void loop() {
  // Modem sleep can delay or drop the TCP back-connection used by espota after the UDP invite.
  static int lastWifiStatus = -1;
  int st = WiFi.status();
  if (st == WL_CONNECTED && lastWifiStatus != WL_CONNECTED) {
    WiFi.setSleep(false);
  }
  lastWifiStatus = st;

  ensureWifi();
}

bool isConnected() { return WiFi.status() == WL_CONNECTED; }

} // namespace WifiManager
