# VuonRau (IoT)

Hệ thống IoT cục bộ: điều khiển van nước (relay), đọc cảm biến, app Flutter gọi REST qua backend Spring Boot; thiết bị ESP32 chỉ giao tiếp MQTT với backend.

## Thành phần chính

| Thư mục | Mô tả |
|--------|--------|
| `backend-java/` | Backend Spring Boot (REST ↔ MQTT, MySQL, Flyway) |
| `esp32/`, `esp32_cam/` | Firmware PlatformIO |
| `flutter_app/` | Ứng dụng Flutter (chỉ REST; không dùng MQTT trực tiếp) |
| `docs/human_vi/` | Tài liệu vận hành / deploy / test (tiếng Việt) |
| `docs/ai_en/` | Đặc tả cho AI maintain (tiếng Anh): API, MQTT, DB |
| `tools/` | Script tiện ích (không bắt buộc khi chạy production) — xem `tools/README.md` |

## Luồng dữ liệu (tóm tắt)

- **Điều khiển:** Flutter → Backend → MQTT → ESP32  
- **Trạng thái / sensor:** ESP32 → MQTT → Backend → Flutter (GET `/devices/.../state`)

## Tài liệu

- Người vận hành: bắt đầu từ [`docs/human_vi/README.md`](docs/human_vi/README.md)  
- Kỹ thuật / AI: [`docs/ai_en/README.md`](docs/ai_en/README.md)

## Build nhanh

- Backend: `cd backend-java && mvn package`  
- Firmware: `cd esp32 && pio run`  
- Flutter: `cd flutter_app && flutter pub get && flutter run`
