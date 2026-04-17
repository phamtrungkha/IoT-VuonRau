package com.vuonrau.exception;

public class UnknownDeviceException extends RuntimeException {

    public UnknownDeviceException() {
        super("Unknown device_id");
    }
}
