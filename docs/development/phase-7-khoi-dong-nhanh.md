# Khởi động nhanh thử nhận dạng (bấm đúp)

Dùng sau khi đã cài đặt xong một lần theo [phase-7-huong-dan-chay.md](phase-7-huong-dan-chay.md) (Docker, `.env`, database thử,
`.local/venv-ml`, trọng số, lớp thử). Các file `.bat` nằm ở thư mục gốc repo.

| Muốn làm                                              | Bấm đúp                        |
| ----------------------------------------------------- | ------------------------------ |
| Dùng trên máy tính                                    | `Bat-nhan-dang.bat`            |
| Dùng trên điện thoại cắm dây USB                      | `Bat-nhan-dang-dien-thoai.bat` |
| Cài app Android lần đầu / khi code giao diện thay đổi | `Cai-app-dien-thoai.bat`       |
| Rút dây rồi cắm lại                                   | `Noi-lai-dien-thoai.bat`       |
| Xong việc                                             | `Tat-nhan-dang.bat`            |

`Bat-nhan-dang*.bat` gọi `scripts/recognition/pilot/up.ps1`, tự làm:

1. Mở Docker Desktop nếu chưa chạy, bật PostgreSQL/Redis/MinIO (`docker compose up -d --wait`).
2. Tắt tiến trình `node`/`python` lạ đang chiếm cổng 3000/8080/8000 (vd cửa sổ `pnpm dev:api` quên tắt). Chương trình khác chiếm
   cổng thì dừng và báo.
3. Thư mục trọng số: biến `PILOT_WEIGHTS_DIR`, nếu không có thì đọc `.local/pilot/weights-dir.txt` (lần đầu hỏi một lần rồi lưu).
   Kiểm đủ 3 file `.pth`, kiểm `.local/venv-ml`, build web nếu chưa có `apps/client_flutter/build/web`.
4. `stack.ps1 start` (recognition, api, dispatcher, worker, web) rồi kiểm sức khỏe; dịch vụ lỗi thì in 20 dòng log cuối.
5. Chế độ điện thoại (`-Usb`): `adb reverse` cổng 8080/3000/9000, nên trên điện thoại `localhost` chính là máy tính — mở app hoặc
   trình duyệt `http://localhost:8080`, ảnh ô (MinIO `localhost:9000`) hiển thị bình thường. Không mở cổng ra mạng LAN, không sửa `.env`.
6. In địa chỉ và tên đăng nhập giáo viên thử (mật khẩu xem `teacherPassword` trong `.local/pilot/pilot.json`).

Điện thoại lần đầu: bật _Tùy chọn nhà phát triển_ → _Gỡ lỗi USB_, dùng dây truyền dữ liệu, bấm _Cho phép gỡ lỗi USB_ trên điện thoại.
`adb` lấy từ Android SDK (`%LOCALAPPDATA%\Android\Sdk\platform-tools`). Chuyển cổng mất khi rút dây/khởi động lại điện thoại → bấm
`Noi-lai-dien-thoai.bat`. Cắm nhiều điện thoại: chạy `up.ps1 -Usb -Serial <mã>` (mã lấy từ `adb devices`).

App Android (`Cai-app-dien-thoai.bat`): build APK debug flavor `development` với `apps/client_flutter/config/android-usb.json`
(`API_BASE_URL = http://localhost:3000`, chỉ chạy qua USB) rồi `adb install -r`.

`Tat-nhan-dang.bat` (`down.ps1`): tắt 5 dịch vụ và gỡ chuyển cổng USB; Docker vẫn chạy, dữ liệu giữ nguyên.
