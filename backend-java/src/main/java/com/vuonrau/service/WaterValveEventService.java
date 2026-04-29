package com.vuonrau.service;

import com.vuonrau.entity.Device;
import com.vuonrau.entity.WaterValveEvent;
import com.vuonrau.repository.DeviceRepository;
import com.vuonrau.repository.WaterValveEventRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class WaterValveEventService {

    private static final Logger log = LoggerFactory.getLogger(WaterValveEventService.class);
    private static final int MQTT_DEDUPE_MANUAL_SECONDS = 5;

    private final WaterValveEventRepository waterValveEventRepository;
    private final DeviceRepository deviceRepository;

    public WaterValveEventService(
            WaterValveEventRepository waterValveEventRepository, DeviceRepository deviceRepository) {
        this.waterValveEventRepository = waterValveEventRepository;
        this.deviceRepository = deviceRepository;
    }

    @Transactional
    public void recordManual(String deviceId, boolean valveOn) {
        insert(deviceId, valveOn, "manual");
    }

    /**
     * Records a valve transition from MQTT/runtime. Skips when it would duplicate a manual row
     * for the same state within a few seconds (optimistic manual log + immediate device echo).
     * Does not throw — failures are logged so MQTT processing continues.
     */
    @Transactional
    public void recordMqttSafe(String deviceId, boolean valveOn) {
        try {
            Instant now = Instant.now();
            var lastOpt = waterValveEventRepository.findTopByDeviceIdOrderByRecordedAtDesc(deviceId);
            if (lastOpt.isPresent()) {
                WaterValveEvent last = lastOpt.get();
                if ("manual".equals(last.getSource())
                        && last.isOnState() == valveOn
                        && ChronoUnit.SECONDS.between(last.getRecordedAt(), now) < MQTT_DEDUPE_MANUAL_SECONDS) {
                    return;
                }
            }
            insert(deviceId, valveOn, "mqtt");
        } catch (Exception e) {
            log.warn("water_valve_events insert failed deviceId={} on={}: {}", deviceId, valveOn, e.toString());
        }
    }

    private void insert(String deviceId, boolean valveOn, String source) {
        if (!deviceRepository.existsById(deviceId)) {
            deviceRepository.save(new Device(deviceId));
        }
        WaterValveEvent row = new WaterValveEvent();
        row.setDeviceId(deviceId);
        row.setOnState(valveOn);
        row.setSource(source);
        row.setRecordedAt(Instant.now());
        waterValveEventRepository.save(row);
    }
}
