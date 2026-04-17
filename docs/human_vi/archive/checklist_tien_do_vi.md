# Checklist tiến độ (ARCHIVED)

Tài liệu này được **lưu trữ** để tham khảo lịch sử. Nội dung có thể **không còn khớp** với source hiện tại.
Vui lòng xem bộ tài liệu mới tại `docs/human_vi/` và `docs/ai_en/`.

Quy ước trạng thái:

- **DONE**: đã có end-to-end và dùng được theo contract hiện tại
- **PARTIAL**: đã có một phần, còn thiếu rõ ràng để đạt yêu cầu trong `system_overview`
- **TODO**: chưa có hoặc chưa đúng yêu cầu

---

## 1) Mục tiêu tổng quát (Purpose)

- **Điều khiển van nước (relay)**: **DONE**
  - **Đã có**: Flutter toggle → Backend REST → MQTT → ESP32 relay (GPIO15) → ack/state → Flutter refresh.
  - **Gợi ý tiếp**: bổ sung thêm màn hình/UX/nhật ký nếu cần (không bắt buộc trong overview).

- **Đọc độ ẩm đất từ ESP32**: **(cũ)**
  - Lưu ý: contract hiện tại dùng `type:"sensor"` + `readings.humidity_raw` (không dùng top-level `humidity`).

- **Single user, không auth**: **DONE**
  - **Đã có**: backend không có auth (phù hợp constraint).

- **Ưu tiên stability hơn realtime**: **DONE**
  - **Đã có**: Flutter không subscribe realtime; chỉ fetch theo refresh/after action.

---

## 2) Kiến trúc & quy tắc giao tiếp

- **Flutter không dùng MQTT trực tiếp**: **DONE**
  - **Đã có**: Flutter gọi REST backend.

- **Backend là cổng duy nhất**: **DONE**

- **ESP32 chỉ giao tiếp qua MQTT**: **DONE**

---

## 3) Device model

- **Device ID `water_controller`**: **DONE**
- **Capabilities `relay`**: **DONE**
- **Capabilities `sensor`**: **TODO**
  - **Thiếu**: sensor handler + data path backend/flutter.

---

## 4) MQTT Design (topics)

- **Topic structure `device/{device_id}/request|response`**: **DONE**
- **Request/Response routing theo `device_id`**: **DONE**

---

## 5) Payload specification

### 5.1 Command (Backend → ESP32)

- **Payload set `water_valve`**: **DONE**
  - Shape: `{ device, action:"set", target:"water_valve", value:bool, request_id? }`

### 5.2 Sensor response (ESP32 → Backend)

- **Payload `type:"sensor", humidity`**: **TODO**
  - **Thiếu**:
    - ESP32: đọc ADC/cảm biến + publish `type:"sensor"` đúng contract
    - Backend: subscribe và lưu humidity vào state store
    - Flutter: hiển thị humidity

### 5.3 State response (ESP32 → Backend)

- **Payload `type:"state", water_valve`**: **DONE**
  - ESP32 publish `state` sau khi xử lý command và theo heartbeat.

### Timestamp

- **`timestamp` là uptime seconds (seconds since boot)**: **DONE**
  - **Đã chốt** trong docs và đang match với firmware.

---

## 6) Backend responsibilities

- **Expose REST API cho Flutter**: **DONE**
- **Publish command ra MQTT**: **DONE**
- **Subscribe MQTT response**: **DONE**
- **Trả latest data cho Flutter theo request**: **PARTIAL**
  - **Đã có**: trả state `water_valve` + `stale` + `updated_at`.
  - **Thiếu**: nếu triển khai sensor thì cần trả thêm humidity.
- **Business logic (schedule + conditions)**: **TODO** (đúng với “Future”)

Constraints:

- **No database, in-memory only**: **DONE**
- **No authentication**: **DONE**

---

## 7) REST API design

- **GET `/devices/{device_id}/state`**: **DONE**
  - **Đã có**: trả `water_valve`, `timestamp`, `updated_at`, `stale`, `last_request_id` (nếu có).

- **POST `/devices/{device_id}/actions`**: **DONE**
  - **Đã có**: validate `target`, publish MQTT, có thể wait ngắn để trả `ok`/`accepted`.
  - **Ghi chú**: khi MQTT chưa connected backend trả `503` (để rõ lỗi môi trường).

---

## 8) ESP32 behavior

- **Subscribe request topic**: **DONE**
- **Publish response topic**: **DONE**
- **Execute command ngay khi nhận**: **DONE**
- **Chỉ send data khi requested**: **PARTIAL**
  - **Đã có**: state sau command (requested by action) là hợp lý.
  - **Chưa đúng hoàn toàn**: vẫn có heartbeat publish state định kỳ (theo overview thì heartbeat được yêu cầu, nên chấp nhận được).
  - **Thiếu**: cơ chế “backend yêu cầu sensor data” (nếu bạn muốn đúng nghĩa “requested” cho sensor).
- **Heartbeat 5–10 phút**: **DONE** (đã có 5 phút)
- **Loop non-blocking / reconnect**: **DONE**

---

## 9) Flutter app behavior

- **Không realtime subscription**: **DONE**
- **Chỉ fetch khi refresh / sau khi gửi command**: **DONE**
- **Không optimistic, luôn re-fetch state**: **DONE**
- **Manual IP/base URL**: **DONE**

---

## 10) Automation (Future design)

- **Schedule + condition**: **TODO**
  - Phụ thuộc: cần có humidity (sensor) trước để điều kiện hoạt động thực tế.

---

## 11) IP handling (Dynamic IP)

- **Backend tự check IP 30 phút/lần + update remote file**: **TODO**
- **Flutter manual IP config**: **DONE** (đã có base URL nhập tay)

---

## 12) Gợi ý thứ tự làm tiếp (ưu tiên)

1. **Sensor humidity end-to-end** (ESP32 → MQTT → backend state → Flutter UI)
2. **Test checklist chạy thực tế**: xem `docs/human_vi/test_checklist_e2e.md`
3. **Automation** (schedule + condition) sau khi có humidity ổn định
4. **Dynamic IP handling** nếu bạn cần truy cập từ ngoài LAN

