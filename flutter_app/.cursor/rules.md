# Flutter Rules

## Architecture

* Use clean structure (UI / logic separation)
* Do NOT call MQTT directly
* Only communicate with Backend API

## Networking

* Use REST API only
* Handle timeout and error properly

## State

* No realtime subscription
* Fetch data only on:

  * user refresh
  * after sending command

## UI Behavior

* Do not assume command success
* Always re-fetch state after action

## Code Quality

* Keep widgets small
* Avoid business logic inside UI
* Use clear naming
