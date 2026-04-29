package com.vuonrau.controller;

import com.vuonrau.dto.HistoryTimelineResponse;
import com.vuonrau.service.DeviceHistoryService;
import java.time.Instant;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/devices")
public class DeviceHistoryController {

    private final DeviceHistoryService deviceHistoryService;

    public DeviceHistoryController(DeviceHistoryService deviceHistoryService) {
        this.deviceHistoryService = deviceHistoryService;
    }

    @GetMapping("/{deviceId}/history/timeline")
    public HistoryTimelineResponse timeline(
            @PathVariable String deviceId,
            @RequestParam Instant from,
            @RequestParam Instant to,
            @RequestParam(defaultValue = "true") boolean humidity,
            @RequestParam(defaultValue = "true") boolean valve,
            @RequestParam(defaultValue = "0") long offset) {
        return deviceHistoryService.loadTimeline(deviceId, from, to, humidity, valve, offset);
    }
}
