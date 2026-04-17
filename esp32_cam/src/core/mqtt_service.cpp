#include "mqtt_service.h"
#include "app_config.h"
#include <Arduino.h>
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <WiFi.h>

namespace {

const uint16_t MQTT_BUFFER_SIZE = 512;
const unsigned long PUBLISH_LOG_INTERVAL_MS = 10UL * 1000UL;
const unsigned long MQTT_RETRY_INTERVAL_MS = 5UL * 1000UL;
const unsigned long MQTT_STUCK_TIMEOUT_MS = 10UL * 60UL * 1000UL;

WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);

bool waterValveOn = false;
unsigned long waterValveOnSinceMs = 0;
int humidityRawLatest = -1;

unsigned long lastMqttAttemptMs = 0;
unsigned long lastMqttRxMs = 0;
unsigned long lastMqttActivityMs = 0;
unsigned long lastPublishLogMs = 0;

String topicRequest() { return String("device/") + DEVICE_ID + "/request"; }

String topicResponse() { return String("device/") + DEVICE_ID + "/response"; }

String topicStatus() { return String("device/") + DEVICE_ID + "/status"; }

uint32_t uptimeSeconds() { return millis() / 1000; }

void logPublishFailureThrottled(const __FlashStringHelper *label,
                                const char *topic,
                                size_t payloadLen) {
  unsigned long now = millis();
  if (now - lastPublishLogMs < PUBLISH_LOG_INTERVAL_MS) {
    return;
  }
  lastPublishLogMs = now;

  Serial.print(F("[mqtt] publish failed ("));
  Serial.print(label);
  Serial.print(F(") topic="));
  Serial.print(topic);
  Serial.print(F(" len="));
  Serial.print((uint32_t)payloadLen);
  Serial.print(F(" state="));
  Serial.println(mqttClient.state());
}

bool publishJson(const JsonDocument &doc, bool retain, const __FlashStringHelper *label) {
  char out[512];
  size_t n = serializeJson(doc, out, sizeof(out));
  String topicStr = topicResponse();
  const char *topic = topicStr.c_str();

  bool ok = mqttClient.publish(topic, (const uint8_t *)out, (unsigned int)n, retain);
  if (ok) {
    lastMqttActivityMs = millis();
    return true;
  }

  logPublishFailureThrottled(label, topic, n);
  return false;
}

void publishAckBool(bool ok, const char *target, bool value, const char *requestIdOrNull,
                    const char *errorOrNull) {
  JsonDocument doc;
  doc["device"] = DEVICE_ID;
  doc["type"] = "ack";
  doc["target"] = target ? target : "";
  doc["value"] = value;
  doc["ok"] = ok;
  if (errorOrNull && errorOrNull[0] != '\0') {
    doc["error"] = errorOrNull;
  }
  doc["timestamp"] = uptimeSeconds();
  if (requestIdOrNull && requestIdOrNull[0] != '\0') {
    doc["request_id"] = requestIdOrNull;
  }
  (void)publishJson(doc, false, F("ack"));
}

void publishAckError(const char *target, const char *requestIdOrNull, const char *errorOrNull) {
  publishAckBool(false, target, waterValveOn, requestIdOrNull, errorOrNull);
}

void handleWaterValve(JsonObject data) {
  const char *action = data["action"] | "";
  if (strcmp(action, "set") != 0) {
    publishAckBool(false, "water_valve", waterValveOn, data["request_id"] | "", "unsupported_action");
    return;
  }

  if (!data["value"].is<bool>()) {
    publishAckBool(false, "water_valve", waterValveOn, data["request_id"] | "", "invalid_value");
    return;
  }

  bool desired = data["value"].as<bool>();
  digitalWrite(RELAY_PIN, desired ? HIGH : LOW);
  waterValveOn = desired;
  waterValveOnSinceMs = desired ? millis() : 0;

  const char *requestId = data["request_id"] | "";
  publishAckBool(true, "water_valve", waterValveOn, requestId, nullptr);
  MqttService::publishState(requestId);
}

void enforceAutoOff() {
  if (!waterValveOn) {
    return;
  }
  if (AUTO_OFF_TIMEOUT_MS == 0) {
    return;
  }
  if (waterValveOnSinceMs == 0) {
    waterValveOnSinceMs = millis();
    return;
  }

  unsigned long now = millis();
  if (now - waterValveOnSinceMs < AUTO_OFF_TIMEOUT_MS) {
    return;
  }

  digitalWrite(RELAY_PIN, LOW);
  waterValveOn = false;
  waterValveOnSinceMs = 0;
  MqttService::publishState(nullptr);
}

void dispatchCommand(JsonObject data) {
  const char *target = data["target"] | "";
  if (strcmp(target, "water_valve") == 0) {
    handleWaterValve(data);
    return;
  }
  publishAckError(target, data["request_id"] | "", "unknown_target");
}

void onMqttMessage(char *topic, uint8_t *payload, unsigned int length) {
  (void)topic;

  unsigned long now = millis();
  lastMqttRxMs = now;
  lastMqttActivityMs = now;

  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, payload, length);
  if (err) {
    return;
  }

  JsonObject data = doc.as<JsonObject>();
  const char *device = data["device"] | "";
  if (strcmp(device, DEVICE_ID) != 0) {
    return;
  }

  dispatchCommand(data);
}

void ensureMqttHealth() {
  if (!mqttClient.connected()) {
    return;
  }

  unsigned long now = millis();
  if (lastMqttActivityMs != 0 && (now - lastMqttActivityMs > MQTT_STUCK_TIMEOUT_MS)) {
    mqttClient.disconnect();
    lastMqttAttemptMs = now - MQTT_RETRY_INTERVAL_MS;
  }
}

void ensureMqtt() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  if (mqttClient.connected()) {
    return;
  }

  unsigned long now = millis();
  if (now - lastMqttAttemptMs < MQTT_RETRY_INTERVAL_MS) {
    return;
  }
  lastMqttAttemptMs = now;

  mqttClient.setServer(MQTT_HOST, (uint16_t)MQTT_PORT);
  mqttClient.setCallback(onMqttMessage);
  mqttClient.setBufferSize(MQTT_BUFFER_SIZE);

  String clientId = String(DEVICE_ID) + "-" + String((uint32_t)ESP.getEfuseMac(), HEX);

  String willTopic = topicStatus();
  if (!mqttClient.connect(clientId.c_str(), willTopic.c_str(), 0, true, "offline")) {
    return;
  }

  mqttClient.subscribe(topicRequest().c_str());

  if (mqttClient.publish(willTopic.c_str(), "online", true)) {
    lastMqttActivityMs = millis();
  }

  MqttService::publishState(nullptr);
}

} // namespace

namespace MqttService {

void setup() {
  // Connection and buffer sizing happen in ensureMqtt() on each attempt.
}

void loop() {
  ensureMqtt();
  enforceAutoOff();

  if (mqttClient.connected()) {
    mqttClient.loop();
    ensureMqttHealth();
  }
}

void publishState(const char *requestIdOrNull) {
  JsonDocument doc;
  doc["device"] = DEVICE_ID;
  doc["type"] = "state";
  doc["water_valve"] = waterValveOn;
  doc["timestamp"] = uptimeSeconds();
  if (requestIdOrNull && requestIdOrNull[0] != '\0') {
    doc["request_id"] = requestIdOrNull;
  }
  (void)publishJson(doc, true, F("state"));
}

void publishSensor() {
  JsonDocument doc;
  doc["device"] = DEVICE_ID;
  doc["type"] = "sensor";
  JsonObject readings = doc["readings"].to<JsonObject>();
  readings["humidity_raw"] = humidityRawLatest;
  doc["timestamp"] = uptimeSeconds();
  (void)publishJson(doc, false, F("sensor"));
}

void setHumidityRaw(int v) { humidityRawLatest = v; }

int humidityRaw() { return humidityRawLatest; }

bool isConnected() { return mqttClient.connected(); }

void reconnectTransportAfterWifiSuspend() {
  if (mqttClient.connected()) {
    mqttClient.disconnect();
  }
  lastMqttAttemptMs = 0;
  Serial.println(F("[mqtt] disconnected transport after WiFi suspend (expect reconnect)"));
}

} // namespace MqttService
