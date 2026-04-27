#pragma once

namespace WifiManager {

void begin();
void loop();
bool isConnected();

/** When true, `loop` skips STA reconnect so another module can own the WiFi stack (e.g. ADC job). */
void setReconnectPaused(bool paused);

/**
 * Call after `sensor_adc_wifi_suspend` finishes (success or timeout): sync internal STA timers/state with the
 * driver so `ensureWifi` backoff and `setSleep` stay consistent across WiFi.off → sample → reconnect cycles.
 */
void afterAdcSuspendCycle(bool wifiConnected);

} // namespace WifiManager
