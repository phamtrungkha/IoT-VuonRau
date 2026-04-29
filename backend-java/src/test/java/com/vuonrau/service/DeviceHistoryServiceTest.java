package com.vuonrau.service;

import static org.junit.jupiter.api.Assertions.*;

import com.vuonrau.dto.HistoryTimelineResponse;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.web.server.ResponseStatusException;

@SpringBootTest
class DeviceHistoryServiceTest {

    @Autowired
    private DeviceHistoryService deviceHistoryService;

    @Test
    void rejectsSpanOver3Days() {
        Instant from = Instant.parse("2026-04-01T00:00:00Z");
        Instant to = Instant.parse("2026-04-05T00:01:00Z");
        assertThrows(
                ResponseStatusException.class,
                () -> deviceHistoryService.loadTimeline("water_controller", from, to, true, true, 0));
    }

    @Test
    void rejectsInvalidOffset() {
        Instant from = Instant.parse("2026-04-01T00:00:00Z");
        Instant to = Instant.parse("2026-04-01T12:00:00Z");
        assertThrows(
                ResponseStatusException.class,
                () -> deviceHistoryService.loadTimeline("water_controller", from, to, true, true, 150));
    }

    @Test
    void emptyWhenNeitherSourceSelected() {
        Instant from = Instant.parse("2026-04-01T00:00:00Z");
        Instant to = Instant.parse("2026-04-01T12:00:00Z");
        HistoryTimelineResponse r =
                deviceHistoryService.loadTimeline("water_controller", from, to, false, false, 0);
        assertTrue(r.items().isEmpty());
        assertFalse(r.hasMore());
    }
}
