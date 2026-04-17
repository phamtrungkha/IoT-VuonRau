# `tools/` — tiện ích phát triển / vận hành

Thư mục này **không** là phần runtime của backend hay app. Chỉ chứa script nhỏ để hỗ trợ debug, kiểm tra DB, v.v.

## Script hiện có

| File | Mục đích |
|------|----------|
| [`db_inspect.py`](db_inspect.py) | Kết nối MySQL (qua `pymysql`), in danh sách bảng, cột và metadata từ `information_schema` — hữu ích khi so sánh schema với Flyway hoặc đếm dữ liệu thử. |

### Chạy `db_inspect.py`

Cần Python 3 + `pymysql` (ví dụ: `pip install pymysql` trong một venv).

Biến môi trường (tùy chọn, có default):

- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- `EXACT_COUNT=1` — chạy `COUNT(*)` từng bảng (có thể chậm trên bảng lớn)

Ví dụ:

```bash
export DB_HOST=127.0.0.1
python3 tools/db_inspect.py
```
