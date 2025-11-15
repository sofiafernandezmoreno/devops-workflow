package com.nn_challenge.nn_devops_challenge.model;

import java.time.Instant;

public class StatusResponse {

    private String status;
    private String message;
    private Instant timestamp;

    public StatusResponse(String status, String message) {
        this.status = status;
        this.message = message;
        this.timestamp = Instant.now();
    }

    public String getStatus() {
        return status;
    }

    public String getMessage() {
        return message;
    }

    public Instant getTimestamp() {
        return timestamp;
    }
}
