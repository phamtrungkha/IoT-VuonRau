package com.vuonrau.service;

import com.fasterxml.jackson.databind.JsonNode;

public final class ActionResult {

    private final boolean timeout;
    private final String requestId;
    private final JsonNode mqttPayload;

    private ActionResult(boolean timeout, String requestId, JsonNode mqttPayload) {
        this.timeout = timeout;
        this.requestId = requestId;
        this.mqttPayload = mqttPayload;
    }

    public static ActionResult ok(String requestId, JsonNode mqttPayload) {
        return new ActionResult(false, requestId, mqttPayload);
    }

    public static ActionResult accepted(String requestId) {
        return new ActionResult(true, requestId, null);
    }

    public boolean isTimeout() {
        return timeout;
    }

    public String getRequestId() {
        return requestId;
    }

    public JsonNode getMqttPayload() {
        return mqttPayload;
    }
}
