#pragma once

namespace MqttService {

void setup();
void loop();

void publishState(const char *requestIdOrNull);
void publishSensor();

void setHumidityRaw(int v);
int humidityRaw();

bool isConnected();

} // namespace MqttService
