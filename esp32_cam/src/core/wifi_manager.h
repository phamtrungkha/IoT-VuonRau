#pragma once

namespace WifiManager {

void begin();
void loop();
bool isConnected();

/** When true, `loop` skips STA reconnect so another module can own the WiFi stack (e.g. ADC job). */
void setReconnectPaused(bool paused);

} // namespace WifiManager
