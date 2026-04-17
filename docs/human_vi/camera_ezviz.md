# Camera EZVIZ (ghi chú tích hợp)

Mục tiêu: tài liệu đủ để maintain tích hợp camera trong app, **không lưu secrets trong repo**.

## 1) Nguyên tắc bảo mật

- Không commit `AppKey`, `AccessToken` thật vào repo.
- Chạy Flutter bằng `--dart-define` hoặc env (CI/secret manager).

## 2) Cấu hình chạy Flutter (ví dụ)

```bash
flutter run -d "<DEVICE_NAME>" \
  --dart-define=EZVIZ_ACCESS_TOKEN="<YOUR_ACCESS_TOKEN>"
```

## 3) iOS: thư mục `ios/EzvizSDK/`

SDK native (file `.a` + headers) **không** nằm trong Git (đã `.gitignore`). Mỗi máy dev cần đặt SDK đúng chỗ theo hướng dẫn EZVIZ/OpenSDK của dự án.

## 4) Lưu ý maintain

- Token có thể hết hạn → cần quy trình refresh token (tuỳ theo EZVIZ/OpenSDK).
- Nếu cần giữ “mẫu” URL `ezopen://...` thì chỉ lưu dạng template (không chứa token).

