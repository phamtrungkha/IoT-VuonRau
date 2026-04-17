# Docs for AI (EN)

Goal: help an AI agent maintain and extend this system **safely** and **cheaply** (minimal churn, stable contracts, forward-compatible payloads).

## Canonical docs

- [`architecture.md`](architecture.md): system responsibilities and invariants
- [`mqtt_contract.md`](mqtt_contract.md): MQTT topics + payloads (device ↔ backend)
- [`rest_api_contract.md`](rest_api_contract.md): REST endpoints (flutter ↔ backend)
- [`db_schema_and_migrations.md`](db_schema_and_migrations.md): MySQL schema + Flyway versions
- [`capabilities_and_ui.md`](capabilities_and_ui.md): `/capabilities` and dynamic UI expectations
- [`runbooks.md`](runbooks.md): operational commands + failure modes

## Non-negotiable invariants

- Flutter MUST NOT talk to MQTT directly.
- MQTT `timestamp` is device uptime seconds (seconds since boot).
- Unknown sensor reading keys MUST be ignored (forward-compatibility).

