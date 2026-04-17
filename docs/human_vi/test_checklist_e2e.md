# Checklist test end-to-end (VuonRau)

Mục tiêu: kiểm tra full flow

Flutter → Backend (REST) → MQTT (Mosquitto) → ESP32 → MQTT → Backend → Flutter

## 0) Assumptions

- `device_id`: `water_controller`
- MQTT topics:
  - Request: `device/water_controller/request`
  - Response: `device/water_controller/response`
- `timestamp` trong MQTT là **uptime seconds** (không phải Unix time).

## 1) Kiểm tra Mosquitto

```bash
sudo systemctl status mosquitto
sudo ss -lntp | grep 1883
```

Terminal A (observe):

```bash
mosquitto_sub -h 127.0.0.1 -p 1883 -v -t "device/water_controller/#"
```

## 2) Chạy backend

```bash
sudo systemctl status vuonrau-backend
curl -sS "http://127.0.0.1:8000/devices/water_controller/state"
```

## 3) Kiểm tra firmware publish

Kỳ vọng thấy MQTT `response` có:

- `type:"state"` (retain) khi device online / sau action
- `type:"sensor"` định kỳ với `readings.humidity_raw`

## 4) Toggle van nước qua REST

Bật:

```bash
curl -sS -X POST "http://127.0.0.1:8000/devices/water_controller/actions" \
  -H "Content-Type: application/json" \
  -d '{"target":"water_valve","value":true}'
```

Tắt:

```bash
curl -sS -X POST "http://127.0.0.1:8000/devices/water_controller/actions" \
  -H "Content-Type: application/json" \
  -d '{"target":"water_valve","value":false}'
```

Kỳ vọng:

- Response trả `status:"ok"` hoặc `status:"accepted"` (timeout chờ thiết bị).
- Terminal MQTT thấy:
  - request có `target:"water_valve"` và `request_id`
  - response có `ack` (và thường là `state`) với cùng `request_id`

Sau đó verify state:

```bash
curl -sS "http://127.0.0.1:8000/devices/water_controller/state"
```

Kỳ vọng:

- `water_valve` phản ánh đúng trạng thái
- `humidity_raw` có dữ liệu sau khi sensor publish
- `stale=false` ngay sau cập nhật
- “Cập nhật gần nhất” trên Dashboard (Flutter) dùng **humidity_updated_at** (không bị thay đổi bởi toggle van)

## 5) Flutter smoke test

1. Nhập Base URL: `http://<BACKEND_IP>:8000`
2. Bấm refresh
3. Toggle van nước ON/OFF
4. Mở “Details” để xem hiển thị dynamic theo `/capabilities` + `/state`

## 6) Failure-mode nhanh

- Backend 503 khi actions: thường do MQTT chưa connected.
- `stale=true`: thiết bị không publish (WiFi/MQTT host sai, mất nguồn, sai topic/device id).

