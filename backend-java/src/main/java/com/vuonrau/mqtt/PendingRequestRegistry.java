package com.vuonrau.mqtt;

import com.fasterxml.jackson.databind.JsonNode;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

@Component
public class PendingRequestRegistry {

    private final ConcurrentHashMap<String, CompletableFuture<JsonNode>> pending = new ConcurrentHashMap<>();

    public CompletableFuture<JsonNode> register(String requestId) {
        CompletableFuture<JsonNode> future = new CompletableFuture<>();
        pending.put(requestId, future);
        return future;
    }

    public void notifyIfWaiting(String requestId, JsonNode payload) {
        if (requestId == null || requestId.isEmpty()) {
            return;
        }
        CompletableFuture<JsonNode> future = pending.get(requestId);
        if (future != null) {
            future.complete(payload);
        }
    }

    public void remove(String requestId, CompletableFuture<JsonNode> future) {
        pending.remove(requestId, future);
    }
}
