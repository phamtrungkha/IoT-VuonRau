# Quy trình update / release (khuyến nghị)

Mục tiêu: update ít rủi ro, rollback được bằng backup.

## 1) Update backend (Spring Boot)

1) Build JAR (máy dev):

```bash
cd backend-java
mvn clean package -DskipTests
```

2) Copy lên server:

```bash
scp "target/vuonrau-backend-0.1.0.jar" <USER>@<SERVER_IP>:/opt/vuonrau/lib/vuonrau-backend.jar
```

3) Restart service:

```bash
sudo systemctl restart vuonrau-backend
sudo journalctl -u vuonrau-backend -n 200 --no-pager
```

4) Smoke check:

```bash
curl -sS "http://127.0.0.1:8000/devices/water_controller/state"
curl -sS "http://127.0.0.1:8000/devices/water_controller/capabilities"
```

Ghi chú:

- Flyway migrations chạy tự động khi backend start.
- Go-live cleanup: migration V5 sẽ drop bảng legacy `device_settings` và `sensor_data` (nếu còn).

## 2) Update firmware (ESP32 / ESP32-CAM)

1) Build:

```bash
cd esp32
pio run
```

2) Upload theo workflow của bạn (PlatformIO upload hoặc tool bạn đang dùng).

3) Observe MQTT:

```bash
mosquitto_sub -h 127.0.0.1 -p 1883 -v -t "device/water_controller/#"
```

## 3) Update Flutter app

- Build/run theo môi trường iOS của bạn.
- Sau update, verify Dashboard + Details page.

## 4) Rollback (gợi ý)

- Backend: lưu JAR version trước để có thể copy lại.
- DB: rollback thật sự nên dựa vào backup (Flyway không tự rollback).

