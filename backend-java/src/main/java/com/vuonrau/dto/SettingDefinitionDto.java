package com.vuonrau.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record SettingDefinitionDto(
        String key,
        String type,
        Object defaultValue,
        Double min,
        Double max,
        String unit,
        String label,
        String description,
        String uiHint) {}

