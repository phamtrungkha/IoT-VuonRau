# Troubleshooting (VuonRau)

## 1) Flutter không điều khiển được van

### Triệu chứng

- App toggle nhưng không đổi trạng thái, hoặc báo lỗi.

### Kiểm tra nhanh

1) Backend sống chưa?

```bash
curl -sS "http://<BACKEND_IP>:8000/devices/water_controller/state"
```

2) Backend có kết nối MQTT không?

```bash
curl -sS "http://<BACKEND_IP>:8000/devices/water_controller/status"
```

3) Mosquitto có chạy không?

```bash
sudo systemctl status mosquitto
sudo ss -lntp | grep 1883
```

4) Có traffic MQTT không?

```bash
mosquitto_sub -h <MOSQUITTO_IP> -p 1883 -v -t "device/water_controller/#"
```

## 2) Backend trả 503 khi POST /actions

Thường do backend chưa connect được MQTT broker.

- Check `app.mqtt.host` / `app.mqtt.port` trong cấu hình backend
- Check broker đang chạy

## 3) `stale=true` lâu

Thường do thiết bị không publish `state`/`sensor`.

- Check WiFi credentials trong firmware
- Check `MQTT_HOST`/`MQTT_PORT`
- Check `DEVICE_ID` có đúng `water_controller` và trùng backend allowlist
- Subscribe MQTT để xem có message device không

## 4) Lỗi Flyway/DB khi khởi động backend

Checklist:

- MySQL credentials đúng
- DB `vuonrau` tồn tại
- Flyway schema history không bị “FAILED” (nếu có, cần `flyway repair` theo quy trình của bạn)

Logs:

```bash
sudo journalctl -u vuonrau-backend -n 200 --no-pager
```

