# Triển khai & vận hành (VuonRau)

Kiến trúc:

Flutter (REST) → Backend (Spring Boot) → MQTT (Mosquitto) → ESP32  
ESP32 → MQTT → Backend → Flutter (GET state)

Ghi chú quan trọng:

- Flutter **không** dùng MQTT trực tiếp.
- `timestamp` trong MQTT là **uptime seconds** (giây từ lúc ESP32 boot).

## 0) Chuẩn bị

Linux server:

- Mosquitto (`1883/tcp`)
- Java 17+ để chạy JAR
- MySQL (`3306/tcp`)

Mạng LAN:

- ESP32 và iPhone truy cập được IP server.
- Mở port:
  - `8000/tcp` backend
  - `1883/tcp` mosquitto
  - `3306/tcp` chỉ cần nếu bạn truy cập DB từ máy khác

## 1) Mosquitto

Cài và bật service (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install -y mosquitto mosquitto-clients
sudo systemctl enable --now mosquitto
sudo systemctl status mosquitto
sudo ss -lntp | grep 1883
```

Test nhanh pub/sub:

Terminal A:

```bash
mosquitto_sub -h 127.0.0.1 -p 1883 -v -t "device/water_controller/#"
```

Terminal B:

```bash
mosquitto_pub -h 127.0.0.1 -p 1883 -t "device/water_controller/request" \
  -m '{"device":"water_controller","action":"set","target":"water_valve","value":true,"request_id":"test"}'
```

## 2) MySQL

Tạo DB/user (ví dụ):

```sql
CREATE DATABASE vuonrau CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'vuonrau'@'%' IDENTIFIED BY 'vuonrau';
GRANT ALL PRIVILEGES ON vuonrau.* TO 'vuonrau'@'%';
FLUSH PRIVILEGES;
```

## 3) Deploy backend (Spring Boot)

Backend nằm ở `backend-java/`.

### 3.1 Deploy theo kiểu “chỉ JAR” (khuyến nghị)

Trên máy dev:

```bash
cd backend-java
mvn clean package -DskipTests
```

Copy JAR lên server (đường dẫn tuỳ bạn):

```bash
scp "backend-java/target/vuonrau-backend-0.1.0.jar" \
  <USER>@<SERVER_IP>:/opt/vuonrau/lib/vuonrau-backend.jar
```

Tạo file cấu hình trên server: `/opt/vuonrau/config/application.yml`

```yaml
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1:3306/vuonrau?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
    username: vuonrau
    password: vuonrau

app:
  mqtt:
    host: 127.0.0.1
    port: 1883
  device:
    allowed-ids:
      - water_controller
```

Chạy thử:

```bash
java -jar /opt/vuonrau/lib/vuonrau-backend.jar \
  --spring.config.additional-location=file:/opt/vuonrau/config/
```

Verify:

```bash
curl -sS "http://127.0.0.1:8000/devices/water_controller/state"
```

### 3.2 Chạy dạng service (systemd)

File `/etc/systemd/system/vuonrau-backend.service`:

```ini
[Unit]
Description=VuonRau Backend (Spring Boot + MQTT + MySQL)
After=network-online.target mysql.service
Wants=network-online.target

[Service]
Type=simple
User=<USER>
WorkingDirectory=/opt/vuonrau
ExecStart=/usr/bin/java -jar /opt/vuonrau/lib/vuonrau-backend.jar --spring.config.additional-location=file:/opt/vuonrau/config/
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable + start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vuonrau-backend
sudo systemctl status vuonrau-backend
sudo journalctl -u vuonrau-backend -f
```

## 4) ESP32 / ESP32-CAM firmware

Firmware dùng PlatformIO (`esp32/`, `esp32_cam/`).

Build:

```bash
cd esp32
pio run
```

Chỉnh cấu hình WiFi/MQTT trong `platformio.ini` (build flags) theo môi trường của bạn.

## 5) Flutter

Chạy app:

```bash
cd flutter_app
flutter pub get
flutter run
```

Trong app, nhập Base URL:

- `http://<BACKEND_IP>:8000`

Xem thêm: [Checklist test end-to-end](test_checklist_e2e.md)

