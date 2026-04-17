package com.vuonrau.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.vuonrau.exception.MqttNotConnectedException;
import com.vuonrau.exception.UnknownDeviceException;
import com.vuonrau.exception.UnsupportedTargetException;
import java.util.Map;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {

    @ExceptionHandler(UnknownDeviceException.class)
    public ResponseEntity<Map<String, String>> unknownDevice(UnknownDeviceException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("detail", ex.getMessage()));
    }

    @ExceptionHandler(UnsupportedTargetException.class)
    public ResponseEntity<Map<String, String>> unsupportedTarget(UnsupportedTargetException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("detail", ex.getMessage()));
    }

    @ExceptionHandler(MqttNotConnectedException.class)
    public ResponseEntity<Map<String, String>> mqttDown(MqttNotConnectedException ex) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of("detail", ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> validation(MethodArgumentNotValidException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("detail", "Invalid request"));
    }

    @ExceptionHandler({MqttException.class, JsonProcessingException.class})
    public ResponseEntity<Map<String, String>> internalPublish(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("detail", ex.getMessage() != null ? ex.getMessage() : "error"));
    }
}
