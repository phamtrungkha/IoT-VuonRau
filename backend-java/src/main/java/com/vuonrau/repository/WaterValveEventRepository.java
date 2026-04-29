package com.vuonrau.repository;

import com.vuonrau.entity.WaterValveEvent;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WaterValveEventRepository extends JpaRepository<WaterValveEvent, Long> {

    Optional<WaterValveEvent> findTopByDeviceIdOrderByRecordedAtDesc(String deviceId);
}
