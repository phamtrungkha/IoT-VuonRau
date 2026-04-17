package com.vuonrau;

import com.vuonrau.config.DeviceProperties;
import com.vuonrau.config.MqttProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties({MqttProperties.class, DeviceProperties.class})
public class VuonRauApplication {

    public static void main(String[] args) {
        SpringApplication.run(VuonRauApplication.class, args);
    }
}
