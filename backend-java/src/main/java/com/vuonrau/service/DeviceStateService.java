package com.vuonrau.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.vuonrau.config.DeviceProperties;
import com.vuonrau.dto.DeviceStateResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Service;

@Service
public class DeviceStateService {

    private final ConcurrentHashMap<String, DeviceRuntimeState> latest = new ConcurrentHashMap<>();
    private final DeviceProperties deviceProperties;
    private final ObjectMapper objectMapper;

    public DeviceStateService(DeviceProperties deviceProperties, ObjectMapper objectMapper) {
        this.deviceProperties = deviceProperties;
        this.objectMapper = objectMapper;
    }

    public void updateFromMqtt(String deviceId, JsonNode payload) {
        Instant now = Instant.now();
        latest.compute(
                deviceId,
                (k, v) -> {
                    DeviceRuntimeState base = v == null ? new DeviceRuntimeState() : v;
                    return base.merge(payload, now);
                });
    }

    public DeviceStateResponse getState(String deviceId) {
        Instant now = Instant.now();
        DeviceRuntimeState s = latest.get(deviceId);
        if (s == null) {
            return new DeviceStateResponse(
                    deviceId,
                    null,
                    null,
                    0.0,
                    Map.of(),
                    Map.of(),
                    Map.of(),
                    null,
                    0.0,
                    true,
                    null);
        }
        double updatedEpoch = s.updatedAt.toEpochMilli() / 1000.0;
        double humidityUpdatedEpoch =
                s.humidityUpdatedAt.equals(Instant.EPOCH) ? 0.0 : s.humidityUpdatedAt.toEpochMilli() / 1000.0;
        Map<String, Object> readings = new LinkedHashMap<>();
        for (var e : s.readings.entrySet()) {
            readings.put(e.getKey(), toWireValue(e.getValue()));
        }
        Map<String, Double> readingsUpdatedAt = new LinkedHashMap<>();
        for (var e : s.readingsUpdatedAt.entrySet()) {
            readingsUpdatedAt.put(e.getKey(), e.getValue().toEpochMilli() / 1000.0);
        }
        Map<String, Object> outputs = new LinkedHashMap<>(s.outputs);
        long ageSec = Duration.between(s.updatedAt, now).getSeconds();
        boolean stale =
                s.updatedAt.equals(Instant.EPOCH) || ageSec > deviceProperties.getStaleAfterSeconds();
        return new DeviceStateResponse(
                deviceId,
                s.waterValve,
                s.humidityRaw,
                humidityUpdatedEpoch,
                readings,
                readingsUpdatedAt,
                outputs,
                s.deviceTimestamp,
                updatedEpoch,
                stale,
                s.lastRequestId);
    }

    public double lastUpdatedEpochSeconds(String deviceId) {
        DeviceRuntimeState s = latest.get(deviceId);
        if (s == null || s.updatedAt.equals(Instant.EPOCH)) {
            return 0.0;
        }
        return s.updatedAt.toEpochMilli() / 1000.0;
    }

    private Object toWireValue(JsonNode v) {
        if (v == null || v.isNull()) return null;
        if (v.isBoolean()) return v.asBoolean();
        if (v.isIntegralNumber()) return v.asLong();
        if (v.isFloatingPointNumber()) return v.asDouble();
        if (v.isTextual()) return v.asText();
        return objectMapper.convertValue(v, Object.class);
    }
}
