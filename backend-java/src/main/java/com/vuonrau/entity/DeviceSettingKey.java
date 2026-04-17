package com.vuonrau.entity;

import java.io.Serializable;
import java.util.Objects;

public class DeviceSettingKey implements Serializable {
    private String deviceId;
    private String settingKey;

    public DeviceSettingKey() {}

    public DeviceSettingKey(String deviceId, String settingKey) {
        this.deviceId = deviceId;
        this.settingKey = settingKey;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public String getSettingKey() {
        return settingKey;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        DeviceSettingKey that = (DeviceSettingKey) o;
        return Objects.equals(deviceId, that.deviceId) && Objects.equals(settingKey, that.settingKey);
    }

    @Override
    public int hashCode() {
        return Objects.hash(deviceId, settingKey);
    }
}

