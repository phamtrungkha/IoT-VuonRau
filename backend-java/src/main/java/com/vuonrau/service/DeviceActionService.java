package com.vuonrau.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.vuonrau.config.DeviceProperties;
import com.vuonrau.dto.ActionRequest;
import com.vuonrau.exception.MqttNotConnectedException;
import com.vuonrau.exception.UnknownDeviceException;
import com.vuonrau.exception.UnsupportedTargetException;
import com.vuonrau.mqtt.MqttClientManager;
import com.vuonrau.mqtt.PendingRequestRegistry;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DeviceActionService {

    private static final long RESPONSE_TIMEOUT_MS = 1500;

    private final DeviceProperties deviceProperties;
    private final MqttClientManager mqttClientManager;
    private final PendingRequestRegistry pendingRequestRegistry;
    private final ObjectMapper objectMapper;
    private final HistoryPersistenceService historyPersistenceService;

    public DeviceActionService(
            DeviceProperties deviceProperties,
            MqttClientManager mqttClientManager,
            PendingRequestRegistry pendingRequestRegistry,
            ObjectMapper objectMapper,
            HistoryPersistenceService historyPersistenceService) {
        this.deviceProperties = deviceProperties;
        this.mqttClientManager = mqttClientManager;
        this.pendingRequestRegistry = pendingRequestRegistry;
        this.objectMapper = objectMapper;
        this.historyPersistenceService = historyPersistenceService;
    }

    public ActionResult execute(String deviceId, ActionRequest body) {
        if (!deviceProperties.isAllowed(deviceId)) {
            throw new UnknownDeviceException();
        }
        if (!"water_valve".equals(body.target())) {
            throw new UnsupportedTargetException();
        }
        if (!mqttClientManager.isConnected()) {
            throw new MqttNotConnectedException();
        }

        String requestId = UUID.randomUUID().toString();
        CompletableFuture<JsonNode> pending = pendingRequestRegistry.register(requestId);
        try {
            ObjectNode payload = objectMapper.createObjectNode();
            payload.put("device", deviceId);
            payload.put("action", "set");
            payload.put("target", "water_valve");
            payload.put("value", body.value());
            payload.put("request_id", requestId);

            mqttClientManager.publishJson(deviceId, payload);
            historyPersistenceService.recordManualIrrigation(deviceId, body.value());

            JsonNode result = pending.get(RESPONSE_TIMEOUT_MS, TimeUnit.MILLISECONDS);
            return ActionResult.ok(requestId, result);
        } catch (ExecutionException e) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    e.getCause() != null ? e.getCause().getMessage() : e.getMessage(),
                    e);
        } catch (TimeoutException e) {
            return ActionResult.accepted(requestId);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return ActionResult.accepted(requestId);
        } catch (MqttException | JsonProcessingException e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, e.getMessage(), e);
        } finally {
            pendingRequestRegistry.remove(requestId, pending);
        }
    }
}
