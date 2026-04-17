package com.vuonrau.repository;

import com.vuonrau.entity.SensorType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SensorTypeRepository extends JpaRepository<SensorType, Long> {
    Optional<SensorType> findByCode(String code);
}

