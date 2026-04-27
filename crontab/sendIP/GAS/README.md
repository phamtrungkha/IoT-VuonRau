# Google Apps Script (GAS) - Public IP registry

## Mục đích
- Nhận public IP từ Linux server (cron) qua `POST`
- Flutter app đọc IP mới nhất qua `GET` (độc lập với backend của bạn)

## File
- `Code.gs`: source GAS (Web App)

## Tạo và deploy Web App
1. Vào Google Apps Script: tạo project mới
2. Copy nội dung `Code.gs` trong repo vào file `Code.gs` của project
3. Đổi `SECRET_KEY = 'REPLACE_ME'` thành 1 chuỗi bí mật (shared secret)
4. Deploy:
   - **Deploy** → **New deployment**
   - Type: **Web app**
   - Execute as: **Me**
   - Who has access: **Anyone** (hoặc “Anyone with the link”)  
     (Vì mình tự kiểm tra bằng `key`, nên vẫn có lớp bảo vệ cơ bản.)
5. Copy URL Web App dạng:
   - `https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec`

## API
### GET: đọc IP mới nhất
Request:
- `GET <GAS_URL>?key=<SECRET_KEY>`

Response (JSON):
- `{ "ok": true, "ip": "1.2.3.4", "updatedAt": 171... }`

### POST: cập nhật IP
Request:
- `POST <GAS_URL>?key=<SECRET_KEY>`
- Header: `Content-Type: application/json`
- Body:

```json
{ "ip": "1.2.3.4", "source": "linux", "host": "my-server", "sentAt": "2026-04-26T08:00:00+07:00" }
```

Response (JSON):
- `{ "ok": true, "ip": "1.2.3.4", "updatedAt": 171... }`

## Test nhanh bằng curl
```bash
GAS_URL="https://script.google.com/macros/s/REPLACE_ME/exec"
KEY="REPLACE_ME"

curl -sS "${GAS_URL}?key=${KEY}"
curl -sS -X POST -H "Content-Type: application/json" \
  -d '{"ip":"1.2.3.4","source":"linux","host":"test","sentAt":"'"$(date -Is)"'"}' \
  "${GAS_URL}?key=${KEY}"
```

## Lưu ý bảo mật
- `key` là mức tối thiểu. Nếu cần mạnh hơn (chống leak key), có thể nâng cấp sang:
  - Google Identity/OAuth, hoặc
  - Firebase + Rules
