# VuonRau Backend (Spring Boot)

Backend điều khiển thiết bị qua MQTT, lưu lịch sử cảm biến và tưới tiêu trên MySQL. State thời gian thực nằm trong bộ nhớ (ConcurrentHashMap); MySQL chỉ dùng cho dữ liệu lịch sử.

Triển khai vận hành đầy đủ (Mosquitto, systemd, Flutter): xem [docs/manual_deploy_ops_vi.md](../docs/manual_deploy_ops_vi.md).

---

## 1. Cài môi trường trên Linux

### Cài Java 17

Ubuntu/Debian (OpenJDK):

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk
```

Kiểm tra:

```bash
java -version
```

Kết quả mong đợi có dòng tương tự `openjdk version "17.x.x"`.

### Cài Maven

```bash
sudo apt install -y maven
```

Kiểm tra:

```bash
mvn -version
```

### Cài MySQL Server

```bash
sudo apt install -y mysql-server
sudo systemctl enable --now mysql
```

Kiểm tra:

```bash
mysql --version
```

---

## 2. Cấu hình MySQL

Đăng nhập MySQL (tùy bản phân phối, có thể cần `sudo mysql`):

```sql
CREATE DATABASE vuonrau CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'vuonrau'@'%' IDENTIFIED BY 'vuonrau';
GRANT ALL PRIVILEGES ON vuonrau.* TO 'vuonrau'@'%';
FLUSH PRIVILEGES;
```

Schema được quản lý bằng **Flyway migrations** (tự chạy khi backend khởi động). Backend dùng `spring.jpa.hibernate.ddl-auto: validate` để đảm bảo schema khớp, tránh drift.

Các bảng “scale-ready” chính:

- `devices`
- `device_settings_kv` (settings theo key-value, có namespace)
- `sensor_types`
- `sensor_readings`

Go-live cleanup:

- Sau khi đã migrate sang schema mới, migration `V5__drop_legacy_tables.sql` sẽ **drop** các bảng legacy: `device_settings`, `sensor_data`.
- Bảng `irrigation_log` vẫn được giữ lại vì backend vẫn dùng để ghi log thao tác tưới.

### Cấu hình kết nối trong `application.yml`

Chỉnh file [src/main/resources/application.yml](src/main/resources/application.yml):

```yaml
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1:3306/vuonrau?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
    username: vuonrau
    password: vuonrau
  jpa:
    hibernate:
      ddl-auto: validate
  flyway:
    enabled: true
    baseline-on-migrate: true

app:
  mqtt:
    host: 127.0.0.1
    port: 1883
    client-id: vuonrau-backend
    username:        # tùy chọn
    password:        # tùy chọn
  device:
    stale-after-seconds: 300
    allowed-ids:
      - water_controller
```

- `allowed-ids`: danh sách `device_id` được phép gọi API (trả 404 nếu không nằm trong danh sách).
- MQTT: subscribe `device/+/response`, publish `device/{deviceId}/request`.

Trên server thật, có thể đặt file cấu hình riêng (ví dụ `/opt/vuonrau/config/application.yml`) và trỏ Spring bằng `--spring.config.additional-location=file:/opt/vuonrau/config/` khi chạy JAR (xem [docs/manual_deploy_ops_vi.md](../docs/manual_deploy_ops_vi.md)).

---

## 3. Build project

Từ thư mục `backend-java` (trên Mac hoặc Linux):

```bash
mvn clean package
```

File JAR chạy được: `target/vuonrau-backend-0.1.0.jar` (theo `artifactId` và `version` trong `pom.xml`).

Chỉ build nhanh, bỏ qua test:

```bash
mvn clean package -DskipTests
```

---

## 4. Copy / đồng bộ lên server Linux (phát triển trên Mac, điều khiển qua SSH)

Hai cách thường dùng; thay `USER`, `SERVER` và đường dẫn cho đúng môi trường (ví dụ `khapt@192.168.1.92`).

### Cách A — Build trên Mac, chỉ đưa JAR lên server (gọn, khuyến nghị)

Sau `mvn clean package` trên Mac:

```bash
scp backend-java/target/vuonrau-backend-0.1.0.jar \
  USER@SERVER:/opt/vuonrau/lib/vuonrau-backend.jar
```

(Tạo thư mục trước trên server: `sudo mkdir -p /opt/vuonrau/lib && sudo chown USER:USER /opt/vuonrau/lib`.)

Nếu bạn chỉnh `application.yml` riêng trên server, copy thêm file đó vào thư mục config (ví dụ `/opt/vuonrau/config/`) rồi chạy JAR với `spring.config.additional-location` như trong tài liệu deploy.

### Cách B — Đồng bộ cả source `backend-java`, build trên Linux

Giống flow cũ với Python nhưng thư mục là `backend-java/`:

```bash
rsync -av --delete \
  "/Volumes/KhaPT/01.Project/git/IoT/VuonRau/backend-java/" \
  USER@SERVER:/opt/vuonrau/backend-java/
```

SSH vào server:

```bash
ssh USER@SERVER
cd /opt/vuonrau/backend-java
mvn clean package -DskipTests
```

JAR nằm tại `target/vuonrau-backend-0.1.0.jar` trên server.

---

## 5. Chạy backend

Trên **máy đã có** Java 17, MySQL đang chạy, Mosquitto (MQTT) đang chạy, và file cấu hình trỏ đúng DB/MQTT:

```bash
java -jar target/vuonrau-backend-0.1.0.jar
```

Hoặc nếu đã copy JAR ra ngoài `target/`:

```bash
java -jar /opt/vuonrau/lib/vuonrau-backend.jar
```

Mặc định HTTP lắng nghe cổng **8000** (`server.port` trong `application.yml`).

---

## 6. Test API bằng `curl`

Thay `water_controller` nếu bạn đổi `allowed-ids`.

### POST — gửi lệnh van nước

```bash
curl -sS -X POST "http://127.0.0.1:8000/devices/water_controller/actions" \
  -H "Content-Type: application/json" \
  -d '{"target":"water_valve","value":true}'
```

- **200**: thiết bị phản hồi trong 1,5 giây (JSON có `status`, `request_id`, `mqtt`).
- **202**: lệnh đã publish nhưng không nhận được phản hồi kịp (`status: accepted`).
- **400**: `target` không hợp lệ.
- **404**: `device_id` không nằm trong whitelist.
- **503**: MQTT chưa kết nối broker.

### GET — state thời gian thực (bộ nhớ)

```bash
curl -sS "http://127.0.0.1:8000/devices/water_controller/state"
```

### GET — trạng thái kết nối MQTT và độ “cũ” của state

```bash
curl -sS "http://127.0.0.1:8000/devices/water_controller/status"
```

---

## Ghi chú triển khai

| Thành phần | Vai trò |
|------------|---------|
| `controller/` | REST: actions, state, status |
| `service/` | Logic nghiệp vụ, state trong RAM |
| `mqtt/` | Eclipse Paho: kết nối, publish/subscribe, `CompletableFuture` theo `request_id` |
| `repository/` + `entity/` | JPA + MySQL (lịch sử) |

- Message MQTT hợp lệ: cập nhật memory trước, sau đó ghi `sensor_readings` nếu `type` là `sensor` và có `readings` (hoặc fallback legacy `humidity_raw`).
- Mỗi lần gọi POST action thành công publish: ghi một dòng `irrigation_log` (`source=manual`, `action=ON` hoặc `OFF`).

---

## Chạy test tự động (Maven)

```bash
mvn test
```

Test sử dụng H2 in-memory (cấu hình trong `src/test/resources/application.yml`), không cần MySQL cục bộ.
