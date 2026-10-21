# ADR-0014 — Nhà trường đặt lịch, hệ thống tự khóa điểm

## Quyết định ngày 2026-10-04

Theo yêu cầu mới nhất, giáo viên không chốt cột/bảng thủ công. QTV đặt thời điểm mở và hạn nhập cho từng `(bảng điểm, thành phần)`, vì mỗi cột thường xuyên có thể có thời hạn riêng. Biểu mẫu hiển thị giờ thiết bị và gửi UTC. Hệ số chỉ dùng cấu hình chung TX/GK/CK của học kỳ; bỏ hệ số thành phần cũ khỏi giao diện, giữ trường/contract deprecated để truy vết và tương thích.

API/DB chỉ cho nhập hoặc duyệt OCR khi `mở ≤ giờ hiện tại < đóng`; chặn upload ngoài lịch. QTV không thay điểm tùy ý bằng API lịch. Chỉ nhận hạn tương lai, phiên QTV hợp lệ, thành phần đúng môn/bảng, optimistic version lịch. Không sửa lịch đã hết hạn hoặc cột/bảng đã khóa; không tự đặt thời hạn cho dữ liệu cũ. Chưa có lịch thì giữ cổng nhập hiện có; phải đặt lịch cho mọi cột để tự khóa toàn bảng.

Đến hạn, giao dịch đồng bộ ô còn thiếu cho học sinh đang học, giữ điểm `DA_DUYET` khác NULL, ghi 0 cho NULL/chưa duyệt kèm lý do lịch nhà trường, đóng phiếu OCR đang xử lý/chờ duyệt thành `LOI` và khóa cột. Không dùng đề xuất OCR chưa được con người duyệt. Điểm 0 của môn Đạt/Không đạt tương ứng Không đạt. Bằng chứng cột và lịch sử append-only; nhật ký thay đổi gắn QTV đặt lịch và lý do tự động, audit thao tác khóa có tác nhân hệ thống. Chốt mọi cột thì bảng `DA_CHOT`, tăng version, vẫn chưa công bố xếp loại.

Tác vụ chạy khi API khởi động và mỗi 30 giây; điều kiện hạn do DB kiểm ngay cả trước tick. Khóa advisory transaction và khóa bảng bảo vệ chạy lặp/cạnh tranh; retry SERIALIZABLE có giới hạn. Không nhận thời gian giả từ client. API chết qua thời hạn thì khi khởi động lại xử lý các lịch quá hạn. Lỗi audit rollback toàn transaction và retry ở tick sau, không log dữ liệu điểm. Runtime chỉ SELECT lịch, thực thi hàm chuyên biệt; thu hồi quyền chốt thủ công cũ. Migration `202610040003_grade_deadlines` tiến tiếp, không sửa migration đã chạy. Rollback bằng migration thu hồi/tạm ngưng executor có review, không xóa điểm 0/lịch sử đã dùng.

## UI admin và kiểm chứng

Bổ sung yêu cầu ngày 2026-10-04: bỏ chọn/ẩn/sắp xếp môn và nút quản lý môn khỏi bảng điểm toàn trường. Tải đủ trang trước khi áp dụng bộ lọc admin. Lịch nhập điểm hiển thị một hàng thẻ cuộn ngang, giữ đầy đủ tên cột, thời gian mở/hạn và thao tác QTV. Thanh cuộn chính vẫn ở mép màn; lịch có thanh cuộn ngang riêng.

Acceptance: PostgreSQL thật kiểm chặn trước/sau hạn, phân quyền QTV/GV, version lịch, không mở lại, bảo toàn 0/điểm duyệt, thêm sĩ số còn thiếu, rollback audit, hai executor không nhân đôi lịch sử. DB constraints kiểm quyền runtime. Flutter kiểm biểu mẫu gửi UTC ở 320/390/1280, role GV không thấy nút chỉnh/chốt và lịch nằm cùng hàng có thể cuộn ngang; widget profile không thay thiết bị Android/iOS thật.

Vận hành: giữ API chạy và giám sát `grade_deadline_failed`; khi lỗi, DB vẫn từ chối ghi sau hạn. Sửa lỗi DB/audit rồi tick sau xử lý. Không dùng seed/reset để khắc phục. Nếu áp dụng thời hạn nhầm, dùng quy trình điều chỉnh có review/migration audit, không bypass khóa qua UI hay role migration của API.

## Bổ sung 2026-10-21: lịch mặc định theo học kỳ, cột không bắt buộc, khởi tạo hàng loạt

- Lịch mặc định đặt theo `(học kỳ, TX/GK/CK)` trong `lich_nhap_hoc_ky`; lịch riêng `(bảng, cột)` hiện có ghi đè. Lịch hiệu lực do `lich_hieu_luc(bảng, thành phần)` trả (riêng nếu có, không thì theo `loai_he_so`); `kiem_thoi_gian_nhap`, `dat_lich_nhap_diem` và `xu_ly_han_nhap_diem` đều dùng nó. Cột không có lịch nào vẫn mở như cũ. QTV đặt lịch học kỳ qua `PUT /catalog/semesters/{id}/deadlines/{type}` (version lạc quan, không sửa lịch đã qua hạn, không đặt khi học kỳ đã công bố).
- Sửa lỗi: hết hạn chỉ ghi 0 + lịch sử cho cột `bat_buoc = true`. Cột không bắt buộc giữ ô trống (NULL/CHUA_CO), không lịch sử, nhưng vẫn bị chốt. Dữ liệu cũ không sửa.
- `POST /catalog/semesters/{id}/gradebooks/initialize` (chỉ QTV, idempotency) tạo bảng điểm còn thiếu cho mọi phân công của học kỳ; lớp không có học sinh đang học hoặc môn chưa có thành phần được báo `skipped` (`EMPTY_ROSTER`, `NO_COMPONENTS`). Giáo viên vẫn tự tạo được; không tạo tự động bằng trigger.

## Bổ sung 2026-10-21: ô Miễn và điều kiện công bố học kỳ

- Ô điểm có thêm trạng thái `MIEN` (giá trị luôn NULL, khác `CHUA_CO`; CHECK `diem_trang_thai`). GV phụ trách đặt/bỏ miễn bằng `PUT /gradebooks/{id}/exemptions` khi cột còn mở (trong khung giờ, chưa chốt, không có phiếu nhận dạng đang xử lý/chờ đối chiếu, chỉ ô đang NULL, lý do 1–500 ký tự); lịch sử append-only ở `lich_su_mien_diem`. Ô MIEN không bị ghi 0 khi hết hạn, không nhận điểm tay (`CELL_EXEMPT`) hay duyệt nhận dạng (`ROW_STUDENT_EXEMPT`), bị bỏ khỏi tử số, mẫu số và danh sách thiếu cột bắt buộc khi tổng kết; học sinh miễn mọi ô nằm trong `exempted`, không có kết quả.
- Học sinh vào lớp SAU khi cột đã chốt: QTV gọi `POST /gradebooks/{id}/late-students` (`them_hoc_sinh_sau_chot`): tạo ô còn thiếu, cột đã chốt → `MIEN` (có lý do), cột còn mở → `CHUA_CO`; không đổi ô đã có; chặn khi học kỳ đã công bố. `GET /gradebooks/{id}/missing-students` liệt kê học sinh thiếu ô.
- Công bố học kỳ kiểm theo MỌI phân công (`kiem_san_sang_cong_bo`, trigger `kiem_cong_bo`): có bảng, bảng `DA_CHOT`, không còn phiếu đang xử lý/chờ đối chiếu, mọi học sinh đang học có ô và có kết quả (trừ học sinh miễn mọi ô). Không có phân công → `NO_RESULTS_TO_PUBLISH`. QTV xem trước bằng `GET /catalog/semesters/{id}/publish-readiness`; bị chặn thì lỗi `TERM_RESULTS_INCOMPLETE` kèm `details.issues`.
