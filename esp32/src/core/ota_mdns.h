#pragma once

/** After WiFi is up: mDNS (`<MDNS_HOSTNAME>.local`) + ArduinoOTA (espota). */
namespace OtaMdns {

void ensureStarted();
void handle();

} // namespace OtaMdns
