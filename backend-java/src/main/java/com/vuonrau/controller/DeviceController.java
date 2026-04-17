package com.vuonrau.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vuonrau.config.DeviceProperties;
import com.vuonrau.config.MqttProperties;
import com.vuonrau.dto.ActionRequest;
import com.vuonrau.dto.DeviceCapabilitiesResponse;
import com.vuonrau.dto.DeviceSettingsKvResponse;
import com.vuonrau.dto.DeviceSettingsPatchRequest;
import com.vuonrau.dto.SettingPatchDto;
import com.vuonrau.dto.SettingValueDto;
import com.vuonrau.dto.DeviceStateResponse;
import com.vuonrau.dto.SystemStatusResponse;
import com.vuonrau.exception.UnknownDeviceException;
import com.vuonrau.mqtt.MqttClientManager;
import com.vuonrau.entity.Device;
import com.vuonrau.entity.DeviceSettingKey;
import com.vuonrau.entity.DeviceSettingKv;
import com.vuonrau.repository.DeviceRepository;
import com.vuonrau.repository.DeviceSettingKvRepository;
import com.vuonrau.repository.SensorTypeRepository;
import com.vuonrau.service.ActionResult;
import com.vuonrau.service.DeviceActionService;
import com.vuonrau.service.DeviceStateService;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/devices")
public class DeviceController {

    private static final long DEFAULT_AUTO_OFF_SECONDS = 30;
    private static final long DEFAULT_MOISTURE_THRESHOLD_RAW = 2000;
    private static final String KEY_AUTO_OFF_SECONDS = "irrigation.auto_off_seconds";
    private static final String KEY_MOISTURE_THRESHOLD_RAW = "irrigation.moisture_threshold_raw";

    private final DeviceProperties deviceProperties;
    private final MqttProperties mqttProperties;
    private final MqttClientManager mqttClientManager;
    private final DeviceStateService deviceStateService;
    private final DeviceActionService deviceActionService;
    private final DeviceRepository deviceRepository;
    private final DeviceSettingKvRepository deviceSettingKvRepository;
    private final SensorTypeRepository sensorTypeRepository;
    private final ObjectMapper objectMapper;

    public DeviceController(
            DeviceProperties deviceProperties,
            MqttProperties mqttProperties,
            MqttClientManager mqttClientManager,
            DeviceStateService deviceStateService,
            DeviceActionService deviceActionService,
            DeviceRepository deviceRepository,
            DeviceSettingKvRepository deviceSettingKvRepository,
            SensorTypeRepository sensorTypeRepository,
            ObjectMapper objectMapper) {
        this.deviceProperties = deviceProperties;
        this.mqttProperties = mqttProperties;
        this.mqttClientManager = mqttClientManager;
        this.deviceStateService = deviceStateService;
        this.deviceActionService = deviceActionService;
        this.deviceRepository = deviceRepository;
        this.deviceSettingKvRepository = deviceSettingKvRepository;
        this.sensorTypeRepository = sensorTypeRepository;
        this.objectMapper = objectMapper;
    }

    @PostMapping("/{deviceId}/actions")
    public ResponseEntity<Map<String, Object>> postAction(
            @PathVariable String deviceId, @Valid @RequestBody ActionRequest body) {
        ActionResult result = deviceActionService.execute(deviceId, body);
        if (result.isTimeout()) {
            Map<String, Object> body202 = new LinkedHashMap<>();
            body202.put("status", "accepted");
            body202.put("request_id", result.getRequestId());
            return ResponseEntity.status(202).body(body202);
        }
        Map<String, Object> ok = new LinkedHashMap<>();
        ok.put("status", "ok");
        ok.put("request_id", result.getRequestId());
        ok.put("mqtt", jsonNodeToMap(result.getMqttPayload()));
        return ResponseEntity.ok(ok);
    }

    @GetMapping("/{deviceId}/state")
    public DeviceStateResponse getState(@PathVariable String deviceId) {
        requireKnownDevice(deviceId);
        return deviceStateService.getState(deviceId);
    }

    @GetMapping("/{deviceId}/status")
    public SystemStatusResponse getStatus(@PathVariable String deviceId) {
        requireKnownDevice(deviceId);
        double now = System.currentTimeMillis() / 1000.0;
        double lastUpdated = deviceStateService.lastUpdatedEpochSeconds(deviceId);
        Double ageS = lastUpdated > 0 ? (now - lastUpdated) : null;
        DeviceStateResponse st = deviceStateService.getState(deviceId);
        return new SystemStatusResponse(
                deviceId,
                now,
                mqttClientManager.isConnected(),
                mqttProperties.getHost(),
                mqttProperties.getPort(),
                lastUpdated,
                ageS,
                st.stale());
    }

    @GetMapping("/{deviceId}/capabilities")
    public DeviceCapabilitiesResponse getCapabilities(@PathVariable String deviceId) {
        requireKnownDevice(deviceId);
        ensureDeviceExists(deviceId);
        ensureDefaults(deviceId);

        // Actuators are still code-driven for safety; expand via a registry later.
        List<String> actuators = List.of("water_valve");

        List<String> sensors =
                sensorTypeRepository.findAll().stream().map(t -> t.getCode()).sorted().toList();

        TreeSet<String> prefixes = new TreeSet<>();
        for (DeviceSettingKv row : deviceSettingKvRepository.findByDeviceIdOrderBySettingKeyAsc(deviceId)) {
            String key = row.getSettingKey();
            if (key == null) continue;
            int dot = key.indexOf('.');
            if (dot <= 0) continue;
            prefixes.add(key.substring(0, dot + 1));
        }
        if (prefixes.isEmpty()) {
            prefixes.add("irrigation.");
        }

        return new DeviceCapabilitiesResponse(deviceId, actuators, sensors, new ArrayList<>(prefixes));
    }

    @GetMapping("/{deviceId}/settings")
    public DeviceSettingsKvResponse getSettings(@PathVariable String deviceId) {
        requireKnownDevice(deviceId);

        ensureDeviceExists(deviceId);
        ensureDefaults(deviceId);

        List<SettingValueDto> out =
                deviceSettingKvRepository.findByDeviceIdOrderBySettingKeyAsc(deviceId).stream()
                        .map(DeviceController::toDto)
                        .toList();
        return new DeviceSettingsKvResponse(deviceId, out);
    }

    @PutMapping("/{deviceId}/settings")
    public DeviceSettingsKvResponse putSettings(
            @PathVariable String deviceId, @Valid @RequestBody DeviceSettingsPatchRequest body) {
        requireKnownDevice(deviceId);

        ensureDeviceExists(deviceId);
        for (SettingPatchDto p : body.patch()) {
            upsertSetting(deviceId, p);
        }
        List<SettingValueDto> out =
                deviceSettingKvRepository.findByDeviceIdOrderBySettingKeyAsc(deviceId).stream()
                        .map(DeviceController::toDto)
                        .toList();
        return new DeviceSettingsKvResponse(deviceId, out);
    }

    private void requireKnownDevice(String deviceId) {
        if (!deviceProperties.isAllowed(deviceId)) {
            throw new UnknownDeviceException();
        }
    }

    private void ensureDeviceExists(String deviceId) {
        if (!deviceRepository.existsById(deviceId)) {
            deviceRepository.save(new Device(deviceId));
        }
    }

    private void ensureDefaults(String deviceId) {
        upsertDefaultInt(deviceId, KEY_AUTO_OFF_SECONDS, DEFAULT_AUTO_OFF_SECONDS);
        upsertDefaultInt(deviceId, KEY_MOISTURE_THRESHOLD_RAW, DEFAULT_MOISTURE_THRESHOLD_RAW);
    }

    private void upsertDefaultInt(String deviceId, String key, long value) {
        DeviceSettingKv row = deviceSettingKvRepository.findById(new DeviceSettingKey(deviceId, key))
                .orElseGet(DeviceSettingKv::new);
        if (row.getDeviceId() == null) {
            row.setDeviceId(deviceId);
            row.setSettingKey(key);
            row.setValueType("int");
            row.setValueInt(value);
            row.setUpdatedAt(Instant.now());
            deviceSettingKvRepository.save(row);
        }
    }

    private void upsertSetting(String deviceId, SettingPatchDto p) {
        DeviceSettingKv row =
                deviceSettingKvRepository
                        .findById(new DeviceSettingKey(deviceId, p.key()))
                        .orElseGet(DeviceSettingKv::new);
        row.setDeviceId(deviceId);
        row.setSettingKey(p.key());
        row.setValueType(p.type());
        row.setUpdatedAt(Instant.now());
        row.setValueInt(null);
        row.setValueDouble(null);
        row.setValueString(null);
        row.setValueJson(null);

        Object v = p.value();
        switch (p.type()) {
            case "int" -> row.setValueInt(((Number) v).longValue());
            case "double" -> row.setValueDouble(((Number) v).doubleValue());
            case "bool" -> row.setValueInt(Boolean.TRUE.equals(v) ? 1L : 0L);
            case "string" -> row.setValueString(String.valueOf(v));
            case "json" -> {
                try {
                    row.setValueJson(objectMapper.writeValueAsString(v));
                } catch (Exception e) {
                    throw new IllegalArgumentException("Invalid json value for key=" + p.key());
                }
            }
            default -> throw new IllegalArgumentException("Unsupported setting type: " + p.type());
        }
        deviceSettingKvRepository.save(row);
    }

    private static SettingValueDto toDto(DeviceSettingKv row) {
        double updatedAtEpochS = row.getUpdatedAt() != null ? row.getUpdatedAt().toEpochMilli() / 1000.0 : 0;
        Object value =
                switch (row.getValueType()) {
                    case "int" -> row.getValueInt();
                    case "double" -> row.getValueDouble();
                    case "bool" -> row.getValueInt() != null && row.getValueInt() != 0;
                    case "string" -> row.getValueString();
                    case "json" -> row.getValueJson();
                    default -> null;
                };
        return new SettingValueDto(row.getSettingKey(), row.getValueType(), value, updatedAtEpochS);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> jsonNodeToMap(JsonNode node) {
        if (node == null) {
            return Map.of();
        }
        return objectMapper.convertValue(node, LinkedHashMap.class);
    }
}
