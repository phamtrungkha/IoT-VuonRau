package com.vuonrau.service;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.HashMap;
import java.util.Map;
import java.time.Instant;

/**
 * In-memory snapshot fields merged from MQTT (mirrors Python StateStore logic).
 */
final class DeviceRuntimeState {

    Boolean waterValve;
    Integer humidityRaw;
    Long deviceTimestamp;
    Instant updatedAt = Instant.EPOCH;
    Instant humidityUpdatedAt = Instant.EPOCH;
    String lastRequestId;
    Map<String, JsonNode> readings = new HashMap<>();
    Map<String, Instant> readingsUpdatedAt = new HashMap<>();
    Map<String, Object> outputs = new HashMap<>();
    Map<String, Instant> outputsUpdatedAt = new HashMap<>();

    /** Effective valve for logging: explicit field wins, else boolean in outputs (e.g. ack path). */
    Boolean effectiveWaterValve() {
        if (waterValve != null) {
            return waterValve;
        }
        Object o = outputs.get("water_valve");
        if (o instanceof Boolean b) {
            return b;
        }
        return null;
    }

    DeviceRuntimeState merge(JsonNode payload, Instant now) {
        String msgType = text(payload, "type");
        if ("state".equals(msgType)) {
            if (payload.has("water_valve") && !payload.get("water_valve").isNull()) {
                waterValve = payload.get("water_valve").asBoolean();
                outputs.put("water_valve", waterValve);
                outputsUpdatedAt.put("water_valve", now);
            }
            if (payload.has("timestamp") && !payload.get("timestamp").isNull()) {
                deviceTimestamp = payload.get("timestamp").asLong();
            }
            String rid = text(payload, "request_id");
            if (rid != null) {
                lastRequestId = rid;
            }
        } else if ("sensor".equals(msgType)) {
            JsonNode readings = payload.get("readings");
            if (readings != null && readings.isObject()) {
                for (var it = readings.fields(); it.hasNext(); ) {
                    var e = it.next();
                    String code = e.getKey();
                    JsonNode v = e.getValue();
                    if (code == null || code.isBlank() || v == null || v.isNull()) {
                        continue;
                    }
                    this.readings.put(code, v);
                    this.readingsUpdatedAt.put(code, now);
                    if ("humidity_raw".equals(code)) {
                        humidityRaw = v.asInt();
                        humidityUpdatedAt = now;
                    }
                }
            } else if (payload.has("humidity_raw") && !payload.get("humidity_raw").isNull()) {
                // Legacy payload (pre-readings map)
                JsonNode hr = payload.get("humidity_raw");
                humidityRaw = hr.asInt();
                humidityUpdatedAt = now;
                this.readings.put("humidity_raw", hr);
                this.readingsUpdatedAt.put("humidity_raw", now);
            }
            if (payload.has("timestamp") && !payload.get("timestamp").isNull()) {
                deviceTimestamp = payload.get("timestamp").asLong();
            }
        } else if ("ack".equals(msgType)) {
            String rid = text(payload, "request_id");
            if (rid != null) {
                lastRequestId = rid;
            }
            // If the device acknowledges a target/value successfully, treat it as an output update.
            if (payload.has("ok") && payload.get("ok").asBoolean(false)) {
                String target = text(payload, "target");
                if (target != null && !target.isBlank() && payload.has("value") && !payload.get("value").isNull()) {
                    JsonNode v = payload.get("value");
                    Object out;
                    if (v.isBoolean()) out = v.asBoolean();
                    else if (v.isIntegralNumber()) out = v.asLong();
                    else if (v.isFloatingPointNumber()) out = v.asDouble();
                    else if (v.isTextual()) out = v.asText();
                    else out = v;
                    outputs.put(target, out);
                    outputsUpdatedAt.put(target, now);
                    if ("water_valve".equals(target) && out instanceof Boolean b) {
                        waterValve = b;
                    }
                }
            }
        }
        updatedAt = now;
        return this;
    }

    private static String text(JsonNode node, String field) {
        if (!node.has(field) || node.get(field).isNull()) {
            return null;
        }
        return node.get(field).asText();
    }
}
