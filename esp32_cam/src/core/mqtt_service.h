#pragma once

namespace MqttService {

void setup();
void loop();

void publishState(const char *requestIdOrNull);
void publishSensor();

void setHumidityRaw(int v);
int humidityRaw();

bool isConnected();

/** Call after STA was toggled for ADC2; avoids PubSubClient staying "connected" on a dead TCP session. */
void reconnectTransportAfterWifiSuspend();

} // namespace MqttService
