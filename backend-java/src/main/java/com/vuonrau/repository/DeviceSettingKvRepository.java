package com.vuonrau.repository;

import com.vuonrau.entity.DeviceSettingKey;
import com.vuonrau.entity.DeviceSettingKv;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeviceSettingKvRepository extends JpaRepository<DeviceSettingKv, DeviceSettingKey> {
    List<DeviceSettingKv> findByDeviceIdOrderBySettingKeyAsc(String deviceId);
}

