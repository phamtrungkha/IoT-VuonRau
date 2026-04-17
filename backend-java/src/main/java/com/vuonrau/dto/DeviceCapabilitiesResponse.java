package com.vuonrau.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import java.util.List;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record DeviceCapabilitiesResponse(
        String deviceId, List<String> actuators, List<String> sensors, List<String> settingsPrefixes) {}

