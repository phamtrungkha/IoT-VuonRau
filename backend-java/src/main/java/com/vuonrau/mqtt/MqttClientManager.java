package com.vuonrau.mqtt;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.vuonrau.config.DeviceProperties;
import com.vuonrau.config.MqttProperties;
import com.vuonrau.service.DeviceStateService;
import com.vuonrau.service.HistoryPersistenceService;
import com.fasterxml.jackson.core.JsonProcessingException;
import jakarta.annotation.PreDestroy;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallbackExtended;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
public class MqttClientManager {

    private static final Logger log = LoggerFactory.getLogger(MqttClientManager.class);
    private static final String RESPONSE_TOPIC_FILTER = "device/+/response";

    private final MqttProperties mqttProperties;
    private final DeviceProperties deviceProperties;
    private final ObjectMapper objectMapper;
    private final DeviceStateService deviceStateService;
    private final HistoryPersistenceService historyPersistenceService;
    private final PendingRequestRegistry pendingRequestRegistry;

    private final AtomicReference<MqttClient> clientRef = new AtomicReference<>();
    private volatile boolean stopped;
    private Thread connectLoop;

    public MqttClientManager(
            MqttProperties mqttProperties,
            DeviceProperties deviceProperties,
            ObjectMapper objectMapper,
            DeviceStateService deviceStateService,
            HistoryPersistenceService historyPersistenceService,
            PendingRequestRegistry pendingRequestRegistry) {
        this.mqttProperties = mqttProperties;
        this.deviceProperties = deviceProperties;
        this.objectMapper = objectMapper;
        this.deviceStateService = deviceStateService;
        this.historyPersistenceService = historyPersistenceService;
        this.pendingRequestRegistry = pendingRequestRegistry;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void startAfterReady() {
        connectLoop =
                new Thread(
                        () -> {
                            while (!stopped) {
                                try {
                                    MqttClient c = ensureClient();
                                    if (!c.isConnected()) {
                                        MqttConnectOptions opts = buildOptions();
                                        c.connect(opts);
                                        c.subscribe(RESPONSE_TOPIC_FILTER, 1);
                                        log.info("MQTT connected to {}", mqttProperties.brokerUrl());
                                    }
                                    Thread.sleep(500);
                                } catch (InterruptedException e) {
                                    Thread.currentThread().interrupt();
                                    break;
                                } catch (Exception e) {
                                    log.debug("MQTT connect/retry: {}", e.toString());
                                    sleepQuiet(2000);
                                }
                            }
                        },
                        "mqtt-connect-loop");
        connectLoop.setDaemon(true);
        connectLoop.start();
    }

    @PreDestroy
    public void shutdown() {
        stopped = true;
        if (connectLoop != null) {
            connectLoop.interrupt();
        }
        MqttClient c = clientRef.get();
        if (c != null && c.isConnected()) {
            try {
                c.disconnect();
            } catch (MqttException ignored) {
            }
            try {
                c.close();
            } catch (MqttException ignored) {
            }
        }
    }

    public boolean isConnected() {
        MqttClient c = clientRef.get();
        return c != null && c.isConnected();
    }

    public void publishJson(String deviceId, ObjectNode payload)
            throws MqttException, JsonProcessingException {
        MqttClient c = clientRef.get();
        if (c == null || !c.isConnected()) {
            throw new IllegalStateException("MQTT client not connected");
        }
        String topic = "device/" + deviceId + "/request";
        byte[] raw = objectMapper.writeValueAsBytes(payload);
        c.publish(topic, raw, 1, false);
    }

    private MqttClient ensureClient() throws MqttException {
        MqttClient existing = clientRef.get();
        if (existing != null) {
            return existing;
        }
        synchronized (this) {
            if (clientRef.get() != null) {
                return clientRef.get();
            }
            String clientId = mqttProperties.getClientId() + "-" + UUID.randomUUID().toString().substring(0, 8);
            MqttClient c =
                    new MqttClient(mqttProperties.brokerUrl(), clientId, new MemoryPersistence());
            c.setCallback(
                    new MqttCallbackExtended() {
                        @Override
                        public void connectComplete(boolean reconnect, String serverURI) {
                            try {
                                MqttClient cli = clientRef.get();
                                if (cli != null && cli.isConnected()) {
                                    cli.subscribe(RESPONSE_TOPIC_FILTER, 1);
                                }
                            } catch (MqttException e) {
                                log.warn("MQTT resubscribe: {}", e.getMessage());
                            }
                        }

                        @Override
                        public void connectionLost(Throwable cause) {
                            log.warn("MQTT connection lost: {}", cause == null ? "" : cause.getMessage());
                        }

                        @Override
                        public void messageArrived(String topic, MqttMessage message) {
                            handleIncoming(topic, message);
                        }

                        @Override
                        public void deliveryComplete(IMqttDeliveryToken token) {}
                    });
            clientRef.set(c);
            return c;
        }
    }

    private void handleIncoming(String topic, MqttMessage message) {
        JsonNode payload;
        try {
            payload =
                    objectMapper.readTree(
                            new String(message.getPayload(), StandardCharsets.UTF_8));
        } catch (Exception e) {
            return;
        }
        String topicDeviceId = deviceIdFromResponseTopic(topic);
        if (topicDeviceId == null) {
            return;
        }
        if (!payload.has("device") || payload.get("device").isNull()) {
            return;
        }
        String bodyDevice = payload.get("device").asText();
        if (!topicDeviceId.equals(bodyDevice)) {
            return;
        }
        if (!deviceProperties.isAllowed(topicDeviceId)) {
            return;
        }
        deviceStateService.updateFromMqtt(topicDeviceId, payload);
        try {
            historyPersistenceService.recordSensorIfApplicable(topicDeviceId, payload);
        } catch (Exception e) {
            log.warn("sensor persist failed: {}", e.getMessage());
        }
        String requestId = text(payload, "request_id");
        if (requestId != null) {
            pendingRequestRegistry.notifyIfWaiting(requestId, payload);
        }
    }

    private static String text(JsonNode node, String field) {
        if (!node.has(field) || node.get(field).isNull()) {
            return null;
        }
        return node.get(field).asText();
    }

    private static String deviceIdFromResponseTopic(String topic) {
        String[] p = topic.split("/");
        if (p.length != 3 || !"device".equals(p[0]) || !"response".equals(p[2])) {
            return null;
        }
        return p[1];
    }

    private MqttConnectOptions buildOptions() {
        MqttConnectOptions opts = new MqttConnectOptions();
        opts.setAutomaticReconnect(true);
        opts.setCleanSession(true);
        opts.setKeepAliveInterval(60);
        if (mqttProperties.getUsername() != null && !mqttProperties.getUsername().isBlank()) {
            opts.setUserName(mqttProperties.getUsername());
            char[] pw =
                    mqttProperties.getPassword() == null
                            ? new char[0]
                            : mqttProperties.getPassword().toCharArray();
            opts.setPassword(pw);
        }
        return opts;
    }

    private static void sleepQuiet(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
