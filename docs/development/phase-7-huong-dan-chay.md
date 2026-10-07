# Hướng dẫn cài và chạy chức năng nhận dạng bảng điểm (Giai đoạn 7) trên máy mới

Dành cho thành viên nhóm clone code về và chạy lại trên **Windows + PowerShell**. Mọi lệnh chạy tại **thư mục gốc repo** (`He_Thong_QL_Diem`), trừ khi có ghi khác.
Tóm tắt những gì đã thay đổi: [phase-7-tong-hop-thay-doi.md](phase-7-tong-hop-thay-doi.md).

Hướng dẫn có hai phần:

- **Phần A**: chạy hệ thống bình thường. Nhận dạng ở chế độ `fake`, không cần mô hình.
- **Phần B**: chạy nhận dạng với **mô hình thật** trên database thử riêng, bằng một lớp có họ tên khớp với ảnh bảng điểm.

---

## 0. Chuẩn bị

**Công cụ** (đúng phiên bản trong README):

- Node 24.19.x và pnpm 11.19.0 (`corepack enable`).
- Docker Desktop (Compose v2).
- Flutter 3.35.7.
- Python **3.12**: chỉ chạy được bản 3.12, kiểm tra bằng `py -3.12 --version`.
- Git.

**File không có trong git**, nhận riêng từ chủ dự án (Drive/USB), **tuyệt đối không commit**:

| File                                 | Dùng cho                                     | SHA-256 bắt buộc                                                   |
| ------------------------------------ | -------------------------------------------- | ------------------------------------------------------------------ |
| `crnn_num_best_dot5.pth`             | đọc Điểm số                                  | `6ca4044d1b7a7c9a51e1b641eade1880461d0d85e5eb4fbf035e827f1afbef91` |
| `vietocr_best_tang4.pth`             | đọc Điểm chữ                                 | `32999513a94f822f4ba4c302749a8d97be0e065631cedceacc0134327f9a73c9` |
| `vietocr_vgg_seq2seq_pretrained.pth` | đọc Họ tên                                   | `0921503a41375a0584268e23ef3d414ea478a8fe8777865c7745d38f2d0bc5db` |
| `class.json`                         | danh sách học sinh của lớp thử, khớp với ảnh | —                                                                  |
| Ảnh bảng điểm mẫu (`.jpg`)           | ảnh để thử                                   | —                                                                  |

- **Không** dùng các file `*_dev.pth`. Các file này chỉ để dò ngưỡng.
- Kiểm tra mã băm của từng file bằng `Get-FileHash <đường dẫn file> -Algorithm SHA256`. Sai mã băm thì dịch vụ từ chối nạp mô hình (`MODEL_UNAVAILABLE`).

---

## Phần A — Chạy hệ thống cơ bản

```powershell
git clone https://github.com/khaiho150405-pixel/He_Thong_QL_Diem.git
cd He_Thong_QL_Diem
git checkout codex/recognition-row-matching      # hoặc main sau khi PR được merge

pnpm install --frozen-lockfile
pnpm setup:local          # tạo .env với mật khẩu ngẫu nhiên (không ghi đè nếu đã có)
pnpm infra:up             # PostgreSQL :5433, Redis, MinIO (Docker Desktop phải đang chạy)
pnpm db:generate
pnpm db:migrate
pnpm db:seed              # tạo tài khoản mẫu; tài khoản admin dùng mật khẩu SEED_PASSWORD trong .env
```

Build giao diện web:

```powershell
dart pub get
dart run melos bootstrap
cd apps/client_flutter
flutter build web --dart-define-from-file=config/development.json
cd ../..
```

Sau đó chạy API và web theo README (`pnpm dev:api`, `node scripts/serve-web.mjs`). Ở chế độ này nhận dạng dùng mô hình **fake**: phù hợp để xem giao diện, nhưng kết quả đọc không phải thật.

---

## Phần B — Nhận dạng bằng mô hình thật (lớp thử)

### B1. Môi trường Python cho mô hình (làm một lần)

```powershell
py -3.12 -m venv .local\venv-ml
.local\venv-ml\Scripts\python -m pip install --upgrade pip
.local\venv-ml\Scripts\python -m pip install -e "apps/recognition-service[ml]"
.local\venv-ml\Scripts\python -m pip install --no-deps vietocr==0.3.13
```

- `vietocr` **bắt buộc** cài với `--no-deps`. Các phụ thuộc mặc định của nó xung đột với `opencv-python-headless`.
- `torch` khá nặng, cài mất vài phút.

Chép 3 file trọng số vào một thư mục, ví dụ `D:\models\weights`.

### B2. Tạo database thử `qld_phase7_test` (làm một lần)

`-U postgres` là `POSTGRES_USER` trong `.env` (mặc định `postgres`). Database này nằm trong cùng cụm PostgreSQL Docker nhưng **tách riêng** khỏi `quan_ly_diem_dev`. Các script dọn dẹp chỉ chạy được trên database có tên kết thúc bằng `_test`.

```powershell
docker compose --env-file .env -f infrastructure/compose.yaml exec -T postgres psql -U postgres -d postgres -c "CREATE DATABASE qld_phase7_test"
docker compose --env-file .env -f infrastructure/compose.yaml exec -T postgres psql -U postgres -d qld_phase7_test -c "GRANT CONNECT, CREATE ON DATABASE qld_phase7_test TO app_migration; REVOKE CREATE ON SCHEMA public FROM PUBLIC; GRANT USAGE, CREATE ON SCHEMA public TO app_migration; GRANT USAGE ON SCHEMA public TO app_runtime;"
```

### B3. Nạp biến môi trường trỏ tới database thử

Mỗi khi mở **cửa sổ PowerShell mới** để chạy `db:migrate`, `db:seed`, `setup.ts`, `reset-tickets.ts` hay `cleanup.ts`, chạy đoạn này trước:

```powershell
Get-Content .env | ForEach-Object { if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { Set-Item "env:$($Matches[1])" $Matches[2].Trim() } }
$env:MIGRATION_DATABASE_URL = "postgresql://app_migration:$($env:MIGRATION_PASSWORD)@127.0.0.1:5433/qld_phase7_test"
$env:TEST_MIGRATION_URL     = $env:MIGRATION_DATABASE_URL
$env:PILOT_WEIGHTS_DIR      = 'D:\models\weights'      # đổi theo thư mục của bạn
```

Sau đó migrate và seed database thử (làm một lần):

```powershell
pnpm db:migrate
pnpm db:seed
```

### B4. Bật các dịch vụ

```powershell
powershell -NoProfile -File scripts/recognition/pilot/stack.ps1 start
powershell -NoProfile -File scripts/recognition/pilot/stack.ps1 status
```

`stack.ps1` bật **5 tiến trình** chạy ngầm. PID và log nằm ở `.local/pilot/`.

| Dịch vụ       | Vai trò                                                                       | Thiếu thì sao                               |
| ------------- | ----------------------------------------------------------------------------- | ------------------------------------------- |
| `recognition` | Python FastAPI :8000, chạy CRNN/VietOCR                                       | phiếu báo lỗi `MODEL_UNAVAILABLE` hoặc treo |
| `api`         | NestJS :3000                                                                  | web không đăng nhập được                    |
| `dispatcher`  | đẩy phiếu mới vào hàng đợi Redis                                              | phiếu nằm mãi ở "Đang xử lý"                |
| `worker`      | gửi ảnh sang `recognition`, ghép học sinh, lưu kết quả                        | phiếu nằm mãi ở "Đang xử lý"                |
| `web`         | giao diện tại http://localhost:8080 (phục vụ `apps/client_flutter/build/web`) | không mở được trang                         |

- `stack.ps1` tự đọc `.env` và trỏ mọi dịch vụ vào `qld_phase7_test` ở chế độ `weights`.
- Thư mục trọng số lấy từ `PILOT_WEIGHTS_DIR`. Nếu không đặt biến này thì mặc định là `D:\HocTap\KhoaLuan\App\weights` (máy chủ dự án).
- Muốn dùng database thử tên khác thì đặt `PILOT_DATABASE` (tên phải kết thúc bằng `_test`).
- Biến `PILOT_WEIGHTS_DIR` phải được đặt **trong cùng cửa sổ PowerShell** trước khi chạy `stack.ps1 start` hoặc `restart`.

Các lệnh khác:

- `stack.ps1 stop`: tắt tất cả.
- `stack.ps1 restart`: khởi động lại tất cả.
- `stack.ps1 restart api`: khởi động lại một dịch vụ. Tên dịch vụ: `recognition`, `api`, `dispatcher`, `worker`, `web`.

### B5. Tạo lớp thử khớp với ảnh

1. Đặt file `class.json` vào `.local/pilot/class.json` (thư mục này đã được git bỏ qua). Định dạng như sau, họ tên in hoa/thường đúng như trên giấy (ví dụ dưới đây là tên giả):

   ```json
   [
     { "stt": 1, "name": "Nguyễn Văn A" },
     { "stt": 2, "name": "Trần Thị B" }
   ]
   ```

2. Chạy các lệnh sau, trong cửa sổ đã chạy B3:

   ```powershell
   pnpm exec tsx scripts/recognition/pilot/setup.ts db      # tạo lớp, học sinh, giáo viên thử, phân công
   pnpm exec tsx scripts/recognition/pilot/setup.ts book    # tạo bảng điểm + mở lịch nhập (API phải đang chạy)
   pnpm exec tsx scripts/recognition/pilot/setup.ts more    # thêm 3 thành phần "Điểm thử nhận dạng 2–4"
   ```

   `book` và `more` đăng nhập bằng admin, dùng `SEED_PASSWORD` trong `.env`.

3. Tài khoản giáo viên thử (`teacherUsername`, `teacherPassword`) được ghi vào `.local/pilot/pilot.json`. **Không** gửi file này lên git hay vào nhóm chat.

4. Đăng nhập web bằng tài khoản giáo viên thử → **Bảng điểm** → mở bảng điểm của lớp thử → bấm **Đồng bộ sĩ số** một lần để tạo ô điểm cho các thành phần mới.

### B6. Nhận dạng một ảnh

1. Trong bảng điểm, mở mục **Nhận dạng bảng điểm từ ảnh**.
2. Chọn **Thành phần điểm**. Chọn thành phần chưa có phiếu chờ, vì mỗi thành phần chỉ có một phiếu chờ tại một thời điểm.
3. Bấm **Chọn ảnh bảng điểm** → **Tải ảnh & Nhận dạng**. Lần đầu sau khi bật dịch vụ mất khoảng 20–25 giây, các lần sau 2–10 giây.
4. Khi phiếu chuyển sang **Chờ đối chiếu**, bấm vào phiếu để mở màn hình **Đối chiếu nhận dạng**:
   - Dùng bộ lọc để xem các dòng **Đỏ** và **Vàng** trước.
   - Mỗi dòng có ảnh ô (bấm để phóng to), **ký tự thô** (chuỗi máy đọc), **giá trị** (điểm đổi từ chuỗi), độ tin cậy và ghi chú ghép tên.
   - Sửa **Điểm cuối** nếu cần. Để trống nghĩa là không ghi điểm, khi đó phải ghi lý do.
5. Bấm **Duyệt** để ghi điểm vào bảng. Đã duyệt thì **không xóa phiếu được nữa**. Nếu chỉ muốn xem thử thì đừng duyệt.

### B7. Công cụ hỗ trợ

Các lệnh `.ts` chạy trong cửa sổ đã chạy B3.

| Lệnh                                                                                | Tác dụng                                                                          |
| ----------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `pnpm exec tsx scripts/recognition/pilot/reset-tickets.ts <mã phiếu>`               | xóa một phiếu **chưa duyệt** (kèm ảnh) để tải lại cùng ảnh                        |
| `pnpm exec tsx scripts/recognition/pilot/reset-tickets.ts CHUA_DUYET`               | xóa mọi phiếu lỗi, đang xử lý hoặc chờ đối chiếu của lớp thử                      |
| `powershell -NoProfile -File scripts/recognition/pilot/check-ticket.ps1 <mã phiếu>` | kiểm tra JSON phiếu so với OpenAPI và in bảng tóm tắt từng dòng (không in họ tên) |
| `pnpm exec tsx scripts/recognition/pilot/cleanup.ts`                                | xóa toàn bộ lớp thử (học sinh, bảng điểm, phiếu, ảnh)                             |

### B8. Sau khi tắt máy, mở lại

1. Mở **Docker Desktop**, chờ đến khi 3 container postgres/redis/minio chạy.
2. Mở PowerShell tại thư mục repo, đặt `$env:PILOT_WEIGHTS_DIR = '...'`.
3. Chạy `powershell -NoProfile -File scripts/recognition/pilot/stack.ps1 start`, rồi `... status` để kiểm tra đủ 5 dịch vụ `running`.

Chỉ chạy web và API thì vẫn tải ảnh lên được, nhưng **sẽ không nhận dạng**: thiếu dispatcher/worker/recognition thì phiếu nằm mãi ở "Đang xử lý".

---

## Xử lý sự cố

| Hiện tượng                                         | Nguyên nhân thường gặp                                                                                             | Cách xử lý                                                                                                    |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| Phiếu nằm mãi ở "Đang xử lý"                       | dispatcher/worker/recognition không chạy                                                                           | `stack.ps1 status`, rồi `stack.ps1 restart dispatcher` và `restart worker`; xem `.local/pilot/logs/*.err.log` |
| "Dữ liệu vi phạm ràng buộc nghiệp vụ…" khi tải ảnh | thành phần đã có phiếu chờ (`RECOGNITION_ALREADY_PENDING`), hoặc ảnh trùng với ảnh của phiếu cũ (`DUPLICATE_FILE`) | chọn thành phần khác, hoặc xóa phiếu cũ bằng `reset-tickets.ts`                                               |
| Màn hình đối chiếu báo "Không thể kết nối dịch vụ" | API tắt, hoặc dữ liệu phiếu không đúng định nghĩa client                                                           | `stack.ps1 status`; chạy `check-ticket.ps1 <mã>` để xem trường bị thiếu hoặc sai                              |
| Phiếu lỗi `MODEL_UNAVAILABLE`                      | sai thư mục trọng số, sai mã băm, venv thiếu torch/vietocr                                                         | kiểm tra `PILOT_WEIGHTS_DIR`, `Get-FileHash`, làm lại B1; xem `.local/pilot/logs/recognition.err.log`         |
| Phiếu lỗi `ROW_MATCH_FAILED`                       | họ tên trên ảnh không khớp danh sách lớp                                                                           | kiểm tra `class.json` có đúng lớp của ảnh không                                                               |
| Nhiều dòng Vàng, ghi chú "Họ tên khớp một phần"    | ảnh mờ hoặc có bóng, đọc thiếu phần tên                                                                            | chụp thẳng, đủ sáng, không có bóng tay; xem phóng to ô họ tên                                                 |
| `TEST_MIGRATION_URL ending with _test is required` | chưa chạy B3 trong cửa sổ PowerShell hiện tại                                                                      | chạy lại đoạn B3                                                                                              |
| Web vẫn là bản cũ                                  | trình duyệt giữ cache                                                                                              | Ctrl+F5; nếu code Flutter đổi thì build lại web rồi `stack.ps1 restart web`                                   |

## Lưu ý an toàn dữ liệu

- **Không commit**: `.env`, `.local/` (venv, `pilot.json`, `class.json`, log), file trọng số, ảnh bảng điểm thật, `apps/client_flutter/config/mobile-lan.json`.
- Không đưa họ tên học sinh thật vào test, log, tài liệu hay commit.
- Không chạy `reset-tickets.ts`, `cleanup.ts` hay test tự động trên `quan_ly_diem_dev`. Các script này tự chặn database không có đuôi `_test`.
- Không sửa sơ đồ phân cấp chức năng. Không tải mô hình từ Internet lúc chạy. Trọng số chỉ nạp với `weights_only=True` sau khi kiểm SHA-256.
