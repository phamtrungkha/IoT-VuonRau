package com.vuonrau.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record SystemStatusResponse(
        String device,
        double backendTime,
        boolean mqttConnected,
        String mqttHost,
        int mqttPort,
        double lastStateUpdatedAt,
        Double lastStateAgeS,
        boolean deviceStale) {}
