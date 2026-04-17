package com.vuonrau.controller;

import com.vuonrau.dto.SettingDefinitionDto;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/settings")
public class SettingsController {

    @GetMapping("/definitions")
    public List<SettingDefinitionDto> getDefinitions() {
        return List.of(
                new SettingDefinitionDto(
                        "irrigation.auto_off_seconds",
                        "int",
                        30,
                        0.0,
                        86400.0,
                        "s",
                        "Auto-off seconds",
                        "Automatically turn off irrigation after N seconds.",
                        "number"),
                new SettingDefinitionDto(
                        "irrigation.moisture_threshold_raw",
                        "int",
                        2000,
                        0.0,
                        4095.0,
                        "raw",
                        "Moisture threshold (raw)",
                        "Threshold used for dry/wet highlighting. Adjust if it seems inverted.",
                        "number"));
    }
}

