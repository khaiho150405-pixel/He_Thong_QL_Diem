---
name: chay-he-thong
description: Cài máy mới, khởi động/tắt hệ thống Quản lý Điểm bằng một click (bản thử và bản deploy Cloudflare), cấu hình tunnel Cloudflare, build APK release ký khóa và cập nhật app. Dùng khi người dùng hỏi cách chạy, deploy, build app, sửa lỗi "không thể kết nối dịch vụ", hoặc cài dịch vụ nhận dạng (venv-ml, trọng số).
---

# Chạy, deploy và phát hành hệ thống

Mọi lệnh chạy ở **thư mục gốc repo**. Trên PowerShell dùng `pnpm.cmd` nếu `pnpm` bị chặn. Các file khởi động nằm ở `Khoi_Dong_Nhan_Dang/` (thư mục này **không nằm trong git**, `*.bat` bị `.gitignore` loại; chép cả thư mục khi sang máy khác, đặt trong thư mục dự án hoặc cạnh `He_Thong_QL_Diem`).

## Khởi động một click

| File (bấm đúp)           | Làm gì                                                                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Khoi-Dong.bat`          | Bản **thử**: Docker + database thử `qld_phase7_test` + 5 dịch vụ (recognition, api, dispatcher, worker, web) + mở `http://localhost:8080`. Đồng thời chạy app trên máy ảo Android Studio (không dùng USB). |
| `Khoi-Dong-Deploy.bat`   | Bản **deploy**: database thật trong `.env`, build web production, 5 dịch vụ, kiểm tra Cloudflare Tunnel, mở `https://eduscore.id.vn`.                       |
| `Tat-nhan-dang.bat`      | Tắt 5 dịch vụ (cả hai chế độ) và gỡ nối USB. Docker vẫn chạy.                                                                                                |
| `Build-APK-Release.bat`  | Build APK production ký khóa release, ra `Khoi_Dong_Nhan_Dang\APK\EduScore.apk`.                                                                             |
| `NangCao\*.bat` | Hiếm dùng: cài app debug qua USB, nối lại USB, máy ảo Android. Xem `Khoi_Dong_Nhan_Dang/HUONG_DAN.txt`. |

Bản thử và bản deploy dùng chung cổng 3000/8080 nên chỉ chạy một trong hai. Logic nằm ở `scripts/recognition/pilot/` (`up.ps1 [-Deploy] [-Usb] [-InstallApp]`, `stack.ps1`, `down.ps1`, `usb-*.ps1`); log và PID ở `.local/pilot/`.

Điều kiện cài một lần (Docker Desktop, `.env`, `.local\venv-ml`, 3 file trọng số `.pth`, lớp thử): xem [references/cai-dat-nhan-dang.md](references/cai-dat-nhan-dang.md). Máy mới và toolchain: [references/may-moi.md](references/may-moi.md), [references/toolchain.md](references/toolchain.md). Lần đầu `up.ps1` hỏi thư mục trọng số rồi nhớ lại.

## Deploy qua Cloudflare

- Web `https://eduscore.id.vn`, API `https://api.eduscore.id.vn`, ảnh `https://storage.eduscore.id.vn`.
- `cloudflared` chạy như dịch vụ Windows (`Get-Service cloudflared`, tự khởi động). Cài mới: dashboard Cloudflare → Networks → Tunnels → Create → chạy lệnh `cloudflared.exe service install <token>` bằng PowerShell quyền Administrator.
- Route trong tunnel (Routes → Add route → Published application), **Service URL phải có giao thức**: `eduscore.id.vn` → `http://localhost:8080`, `api` → `http://localhost:3000`, `storage` → `http://localhost:9000`. Nếu `cloudflared` chạy trong Docker thì thay `localhost` bằng `host.docker.internal`.
- `.env` cần `ALLOWED_ORIGINS` có `https://eduscore.id.vn` và `S3_PUBLIC_ENDPOINT=https://storage.eduscore.id.vn` (API ký URL ảnh bằng địa chỉ này; điện thoại không mở được `localhost:9000`). `S3_ENDPOINT` giữ `http://localhost:9000`.
- Kiểm tra từ ngoài mạng nhà (4G): `/api/v1/health/ready` trên API trả 200, `storage.../minio/health/live` trả 200.
- 502 từ Cloudflare = tunnel chạy nhưng API/MinIO phía sau chưa bật → bấm `Khoi-Dong-Deploy.bat`. Client tự thử lại GET 2 lần khi mất kết nối/502-504; thông báo lỗi phân loại quá chậm / máy chủ bận / mất mạng.

## Build và cập nhật APK

1. `config/production.json` trỏ `https://api.eduscore.id.vn` (đóng sẵn vào APK lúc build).
2. Khóa ký: `apps/client_flutter/android/app-release.jks` + `key.properties` (ngoài git, tự tạo lần đầu bởi `Build-APK-Release.bat`). **Sao lưu hai file này**; mất khóa thì không cập nhật được app đã cài.
3. Lệnh gốc: `flutter build apk --release --flavor production --dart-define-from-file=config/production.json` (trong `apps/client_flutter`). Cần JDK 17+ (JBR của Android Studio); lỗi Gradle `Unable to establish loopback connection` thường do VPN/phần mềm diệt virus chặn loopback.
4. **Phải build lại** khi đổi code Flutter, `production.json`, `pubspec.yaml`, Dart client sinh lại hoặc cấu hình Android. **Không cần** khi chỉ đổi API, `.env`, migration, Cloudflare hay web. Khi cập nhật app đã cài: ký cùng khóa và **tăng số sau dấu `+`** của `version` trong `pubspec.yaml`; cài đè, không mất đăng nhập. Không cần xóa APK cũ (file bị ghi đè).
5. Contract thay đổi: `pnpm api:export` rồi `pnpm client:generate` (cần JDK 11+ trong PATH; Java 8 sẽ lỗi `UnsupportedClassVersionError`).

## Phiên đăng nhập

- Web: cookie `HttpOnly`, phiên 8 giờ / 30 phút không hoạt động.
- App di động: lưu mã ghi nhớ 30 ngày trong Keychain/Keystore (`flutter_secure_storage`), đổi lấy phiên mới qua `POST /identity/resume`; mã dùng một lần, xóa khi đăng xuất/đổi mật khẩu/sửa tài khoản (bảng `phien_ghi_nho`).
- Hệ thống chỉ có **một** quản trị viên; API từ chối cấp vai `QUAN_TRI_VIEN` cho tài khoản khác.
