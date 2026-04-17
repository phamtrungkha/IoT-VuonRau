package com.vuonrau.service;

import static org.junit.jupiter.api.Assertions.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class DeviceRuntimeStateTest {

    private final ObjectMapper om = new ObjectMapper();

    @Test
    void sensorReadingsUpdatePerKeyTimestamps() throws Exception {
        DeviceRuntimeState s = new DeviceRuntimeState();
        Instant t1 = Instant.ofEpochSecond(1000);

        s.merge(
                om.readTree(
                        """
                        {"type":"sensor","device":"water_controller","readings":{"humidity_raw":2559,"temperature_c":29.4},"timestamp":10}
                        """),
                t1);

        assertEquals(2559, s.humidityRaw);
        assertEquals(t1, s.humidityUpdatedAt);
        assertEquals(t1, s.readingsUpdatedAt.get("humidity_raw"));
        assertEquals(t1, s.readingsUpdatedAt.get("temperature_c"));
        assertTrue(s.readings.containsKey("humidity_raw"));
        assertTrue(s.readings.containsKey("temperature_c"));
    }

    @Test
    void ackDoesNotChangeHumidityUpdatedAt() throws Exception {
        DeviceRuntimeState s = new DeviceRuntimeState();
        Instant t1 = Instant.ofEpochSecond(1000);
        Instant t2 = Instant.ofEpochSecond(2000);

        s.merge(
                om.readTree(
                        """
                        {"type":"sensor","device":"water_controller","readings":{"humidity_raw":2500},"timestamp":10}
                        """),
                t1);
        assertEquals(t1, s.humidityUpdatedAt);

        s.merge(
                om.readTree(
                        """
                        {"type":"ack","device":"water_controller","target":"water_valve","value":true,"ok":true,"request_id":"r1","timestamp":11}
                        """),
                t2);

        assertEquals(t1, s.humidityUpdatedAt, "ACK must not update humidity timestamp");
        assertEquals(Boolean.TRUE, s.outputs.get("water_valve"));
        assertEquals(t2, s.outputsUpdatedAt.get("water_valve"));
    }

    @Test
    void stateUpdatesOutputAndOverallUpdatedAt() throws Exception {
        DeviceRuntimeState s = new DeviceRuntimeState();
        Instant t1 = Instant.ofEpochSecond(1000);

        s.merge(
                om.readTree(
                        """
                        {"type":"state","device":"water_controller","water_valve":false,"timestamp":12}
                        """),
                t1);

        assertEquals(Boolean.FALSE, s.waterValve);
        assertEquals(Boolean.FALSE, s.outputs.get("water_valve"));
        assertEquals(t1, s.outputsUpdatedAt.get("water_valve"));
        assertEquals(t1, s.updatedAt);
    }
}

