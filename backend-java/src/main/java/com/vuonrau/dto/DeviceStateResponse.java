package com.vuonrau.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import java.util.Map;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record DeviceStateResponse(
        String device,
        Boolean waterValve,
        Integer humidityRaw,
        double humidityUpdatedAt,
        Map<String, Object> readings,
        Map<String, Double> readingsUpdatedAt,
        Map<String, Object> outputs,
        Long timestamp,
        double updatedAt,
        boolean stale,
        String lastRequestId) {}
