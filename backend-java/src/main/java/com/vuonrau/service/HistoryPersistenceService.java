package com.vuonrau.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vuonrau.entity.Device;
import com.vuonrau.entity.IrrigationLog;
import com.vuonrau.entity.SensorReading;
import com.vuonrau.entity.SensorType;
import com.vuonrau.repository.DeviceRepository;
import com.vuonrau.repository.IrrigationLogRepository;
import com.vuonrau.repository.SensorReadingRepository;
import com.vuonrau.repository.SensorTypeRepository;
import java.time.Instant;
import java.util.Iterator;
import java.util.Map;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class HistoryPersistenceService {

    private final DeviceRepository deviceRepository;
    private final SensorTypeRepository sensorTypeRepository;
    private final SensorReadingRepository sensorReadingRepository;
    private final IrrigationLogRepository irrigationLogRepository;
    private final ObjectMapper objectMapper;
    private final WaterValveEventService waterValveEventService;

    public HistoryPersistenceService(
            DeviceRepository deviceRepository,
            SensorTypeRepository sensorTypeRepository,
            SensorReadingRepository sensorReadingRepository,
            IrrigationLogRepository irrigationLogRepository,
            ObjectMapper objectMapper,
            WaterValveEventService waterValveEventService) {
        this.deviceRepository = deviceRepository;
        this.sensorTypeRepository = sensorTypeRepository;
        this.sensorReadingRepository = sensorReadingRepository;
        this.irrigationLogRepository = irrigationLogRepository;
        this.objectMapper = objectMapper;
        this.waterValveEventService = waterValveEventService;
    }

    @Transactional
    public void recordSensorIfApplicable(String deviceId, JsonNode payload) {
        if (!"sensor".equals(text(payload, "type"))) {
            return;
        }
        ensureDeviceExists(deviceId);

        Instant now = Instant.now();
        JsonNode readings = payload.get("readings");
        if (readings != null && readings.isObject()) {
            Iterator<Map.Entry<String, JsonNode>> it = readings.fields();
            while (it.hasNext()) {
                Map.Entry<String, JsonNode> e = it.next();
                recordOne(deviceId, e.getKey(), e.getValue(), now);
            }
            return;
        }

        // Legacy payload (pre-readings map)
        if (payload.has("humidity_raw") && !payload.get("humidity_raw").isNull()) {
            recordOne(deviceId, "humidity_raw", payload.get("humidity_raw"), now);
        }
    }

    private void recordOne(String deviceId, String sensorCode, JsonNode valueNode, Instant now) {
        if (sensorCode == null || sensorCode.isBlank() || valueNode == null || valueNode.isNull()) {
            return;
        }

        String valueType;
        Long vInt = null;
        Double vDouble = null;
        String vString = null;
        String vJson = null;

        if (valueNode.isIntegralNumber()) {
            valueType = "int";
            vInt = valueNode.asLong();
        } else if (valueNode.isFloatingPointNumber()) {
            valueType = "double";
            vDouble = valueNode.asDouble();
        } else if (valueNode.isBoolean()) {
            valueType = "bool";
            vInt = valueNode.asBoolean() ? 1L : 0L;
        } else if (valueNode.isTextual()) {
            valueType = "string";
            vString = valueNode.asText();
        } else {
            valueType = "json";
            try {
                vJson = objectMapper.writeValueAsString(valueNode);
            } catch (JsonProcessingException e) {
                return;
            }
        }

        SensorType st = findOrCreateSensorType(sensorCode, valueType);
        SensorReading row = new SensorReading();
        row.setDeviceId(deviceId);
        row.setSensorType(st);
        row.setValueInt(vInt);
        row.setValueDouble(vDouble);
        row.setValueString(vString);
        row.setValueJson(vJson);
        row.setCapturedAt(now);
        row.setIngestedAt(now);
        sensorReadingRepository.save(row);
    }

    private SensorType findOrCreateSensorType(String code, String valueType) {
        Optional<SensorType> existing = sensorTypeRepository.findByCode(code);
        if (existing.isPresent()) {
            return existing.get();
        }
        SensorType st = new SensorType();
        st.setCode(code);
        st.setValueType(valueType);
        return sensorTypeRepository.save(st);
    }

    private void ensureDeviceExists(String deviceId) {
        if (!deviceRepository.existsById(deviceId)) {
            deviceRepository.save(new Device(deviceId));
        }
    }

    @Transactional
    public void recordManualIrrigation(String deviceId, boolean valveOn) {
        ensureDeviceExists(deviceId);
        IrrigationLog row = new IrrigationLog();
        row.setDeviceId(deviceId);
        row.setAction(valveOn ? "ON" : "OFF");
        row.setSource("manual");
        row.setCreatedAt(Instant.now());
        irrigationLogRepository.save(row);
        waterValveEventService.recordManual(deviceId, valveOn);
    }

    private static String text(JsonNode node, String field) {
        if (!node.has(field) || node.get(field).isNull()) {
            return null;
        }
        return node.get(field).asText();
    }
}
