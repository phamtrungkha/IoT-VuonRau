package com.vuonrau.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "device_settings_kv")
@IdClass(DeviceSettingKey.class)
public class DeviceSettingKv {

    @Id
    @Column(name = "device_id", nullable = false, length = 128)
    private String deviceId;

    @Id
    @Column(name = "setting_key", nullable = false, length = 128)
    private String settingKey;

    @Column(name = "value_type", nullable = false, length = 16)
    private String valueType;

    @Column(name = "value_int")
    private Long valueInt;

    @Column(name = "value_double")
    private Double valueDouble;

    @Column(name = "value_string", columnDefinition = "text")
    private String valueString;

    @Column(name = "value_json", columnDefinition = "json")
    private String valueJson;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public String getSettingKey() {
        return settingKey;
    }

    public void setSettingKey(String settingKey) {
        this.settingKey = settingKey;
    }

    public String getValueType() {
        return valueType;
    }

    public void setValueType(String valueType) {
        this.valueType = valueType;
    }

    public Long getValueInt() {
        return valueInt;
    }

    public void setValueInt(Long valueInt) {
        this.valueInt = valueInt;
    }

    public Double getValueDouble() {
        return valueDouble;
    }

    public void setValueDouble(Double valueDouble) {
        this.valueDouble = valueDouble;
    }

    public String getValueString() {
        return valueString;
    }

    public void setValueString(String valueString) {
        this.valueString = valueString;
    }

    public String getValueJson() {
        return valueJson;
    }

    public void setValueJson(String valueJson) {
        this.valueJson = valueJson;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}

