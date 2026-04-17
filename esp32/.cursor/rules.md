# ESP32 Rules

## Context

* Always read: esp32/docs/architecture.md before coding

---

## Core Principles

* Do NOT overwrite existing features
* Do NOT remove existing logic unless explicitly required
* Always extend the system, never rewrite it

---

## Command Handling

* Use dispatcher pattern
* Each target must have its own handler function
* Do NOT put all logic in a single function

---

## Extensibility

* All features must be modular
* Adding new feature must NOT affect existing ones
* Avoid hardcoding single-device logic

---

## MQTT

* Subscribe: device/{device_id}/request
* Publish: device/{device_id}/response
* Always handle reconnect

---

## Loop Behavior

* loop() must be non-blocking
* Avoid delay()
* Keep system responsive

---

## Error Handling

* Ignore invalid JSON safely
* Do NOT crash on bad input

---

## Sensor & State

* Only send data when requested
* Include timestamp in responses
* Add heartbeat every 5–10 minutes

---
