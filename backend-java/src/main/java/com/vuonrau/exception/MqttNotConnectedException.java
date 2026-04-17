package com.vuonrau.exception;

public class MqttNotConnectedException extends RuntimeException {

    public MqttNotConnectedException() {
        super("MQTT not connected");
    }
}
