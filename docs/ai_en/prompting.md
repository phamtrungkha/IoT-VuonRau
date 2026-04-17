# Prompting notes (for maintainers)

This file replaces legacy `prompt-template.txt` and `prompt-water.txt`.

## System constraints (repeat in prompts)

- Flutter MUST NOT use MQTT directly.
- Backend is the only entry point.
- Device firmware uses a dispatcher pattern by `target`.

## Preferred delivery style for changes

- Make additive changes when extending (`readings` map, KV settings).
- Keep control-plane targets stable (`water_valve`).
- Keep changes small and verify via smoke tests (`curl`, MQTT observe).

