# Linux cron: gửi Public IP lên Google Apps Script (GAS)

## Mục đích
- Linux server sẽ định kỳ lấy **public IPv6** và gửi lên GAS (kênh độc lập với backend).
- Flutter app sẽ đọc IP mới nhất từ GAS để hiển thị gợi ý trong Settings.

## File
- `send_ip_to_gas.sh`: script lấy public IP và POST lên GAS.

## Cấu hình
Script hỗ trợ cấu hình qua biến môi trường:
- `GAS_URL`: URL Web App của GAS (ví dụ `https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec`)
- `GAS_KEY`: shared secret
- `IP_PROVIDER_URL`: mặc định `https://api64.ipify.org` (IPv6)
- `CURL_TIMEOUT_S`: mặc định `10`
- `CACHE_FILE`: mặc định `/tmp/send_ip_to_gas.last_ip` (để tránh gửi khi IP không đổi)

## Chạy thử (manual)
Ví dụ:

```bash
chmod +x crontab/sendIP/linux/send_ip_to_gas.sh
GAS_URL="https://script.google.com/macros/s/AKfycbyCWLppAfCVZ3Uk65mXO2yaJWU69N39f8v__pVvpvchvaA-Eadd8SyIhe601NB4CtrDIw/exec" \
GAS_KEY="vuonrauiotip" \
./crontab/sendIP/linux/send_ip_to_gas.sh
```

Nếu thành công sẽ log kiểu: `OK: posted public IP ...`

## Cấu hình crontab
Mở crontab:

```bash
crontab -e
```

Ví dụ chạy mỗi 30 phút và ghi log:

```bash
*/30 * * * * GAS_URL="https://script.google.com/macros/s/AKfycbyCWLppAfCVZ3Uk65mXO2yaJWU69N39f8v__pVvpvchvaA-Eadd8SyIhe601NB4CtrDIw/exec" GAS_KEY="vuonrauiotip" /bin/bash /path/to/repo/crontab/sendIP/linux/send_ip_to_gas.sh >> /var/log/send_ip_to_gas.log 2>&1
```

Gợi ý:
- Nếu server của bạn không có quyền ghi `/var/log/`, đổi sang `~/send_ip_to_gas.log`.
- Nếu muốn luôn gửi (không skip khi IP không đổi) thì set `CACHE_FILE` sang path không tồn tại hoặc xoá đoạn cache trong script.

## Deploy nhanh lên server (1 lệnh)
Trong cùng folder có `deploy.sh` để bạn chạy 1 lệnh là:
- upload `send_ip_to_gas.sh` lên server
- cài (hoặc update) crontab entry theo marker `# vuonrau-sendip`

Ví dụ:

```bash
chmod +x crontab/sendIP/linux/deploy.sh
DEPLOY_USER=khapt \
DEPLOY_HOST=192.168.1.92 \
GAS_URL="https://script.google.com/macros/s/AKfycbyCWLppAfCVZ3Uk65mXO2yaJWU69N39f8v__pVvpvchvaA-Eadd8SyIhe601NB4CtrDIw/exec" \
GAS_KEY="vuonrauiotip" \
./crontab/sendIP/linux/deploy.sh
```

Mặc định script sẽ deploy vào `~/vuonrau/sendip` trên server để **không cần sudo**.
Nếu bạn muốn deploy vào `/opt/vuonrau/...` thì set `REMOTE_DIR=/opt/vuonrau/sendip` và đảm bảo user có quyền (hoặc dùng sudo passwordless và set `USE_SUDO=1`).

Nếu bạn buộc dùng password (không khuyến nghị), bạn có thể cài `sshpass` và tự wrap lệnh `ssh/scp` (script này ưu tiên SSH key, giống `backend-java/scripts/deploy-remote.sh`).
