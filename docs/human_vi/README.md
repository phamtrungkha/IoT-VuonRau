# Tài liệu vận hành (Human / VI)

Mục tiêu: tài liệu **ngắn gọn – copy/paste chạy được – phục vụ go-live và vận hành**.

## Bắt đầu nhanh

- [Triển khai & vận hành](deploy_ops.md)
- [Checklist test end-to-end](test_checklist_e2e.md)
- [Troubleshooting](troubleshooting.md)
- [Quy trình update/release](release_update_process.md)
- [Camera EZVIZ](camera_ezviz.md)

## Quy ước

- Flutter **không** dùng MQTT trực tiếp. Flutter chỉ gọi REST của backend.
- `timestamp` trong payload MQTT là **uptime seconds** (giây từ lúc ESP32 boot), **không** phải Unix time.

