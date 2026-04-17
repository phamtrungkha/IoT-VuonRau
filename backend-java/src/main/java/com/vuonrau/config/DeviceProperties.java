package com.vuonrau.config;

import java.util.ArrayList;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.device")
public class DeviceProperties {

    private int staleAfterSeconds = 300;
    private List<String> allowedIds = new ArrayList<>(List.of("water_controller"));

    public int getStaleAfterSeconds() {
        return staleAfterSeconds;
    }

    public void setStaleAfterSeconds(int staleAfterSeconds) {
        this.staleAfterSeconds = staleAfterSeconds;
    }

    public List<String> getAllowedIds() {
        return allowedIds;
    }

    public void setAllowedIds(List<String> allowedIds) {
        this.allowedIds = allowedIds != null ? allowedIds : new ArrayList<>();
    }

    public boolean isAllowed(String deviceId) {
        return allowedIds != null && allowedIds.contains(deviceId);
    }
}
