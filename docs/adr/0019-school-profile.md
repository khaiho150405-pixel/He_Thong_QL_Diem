# ADR-0019: Thông tin trường

- Trạng thái: chấp nhận (2026-10-28), mức 1 "mỗi trường một bản cài"
- Liên quan: `AGENTS.md` mục 3 (một trường/tenant), mục 9 (kiểm tra upload, signed URL); ADR-0005; ADR-0018

## Bối cảnh

Tên "THPT Bà Điểm" được viết cứng trong giao diện, không có trong cơ sở dữ liệu. Quản trị viên (QTV) cần tự sửa tên, cơ quan chủ quản, địa chỉ, liên hệ, hiệu trưởng và logo; màn đăng nhập (chưa có phiên) cũng phải hiển thị được.

## Quyết định

- **Mức 1: mỗi trường một bản cài.** Hệ thống vẫn là một trường/tenant như `AGENTS.md` mục 3; không thêm multi-tenancy.
- Bảng `truong` với khóa `ma_truong smallint` và `CHECK (ma_truong = 1)`. Đặt tên và khóa như một bảng nhiều dòng để mở rộng sau không phải làm lại: khi cần nhiều trường chỉ nới CHECK, thêm `ma_truong` vào các bảng danh mục (năm học, lớp, người dùng…) và chọn trường theo phiên. Migration chèn sẵn dòng mặc định (Trường THPT Bà Điểm) để DB đang dùng có dữ liệu mà không phụ thuộc seed; seed chỉ `ON CONFLICT DO NOTHING`.
- Runtime chỉ `SELECT`; ghi qua hai hàm `SECURITY DEFINER` theo mẫu chung (phiên còn hạn, vai trò QTV, SERIALIZABLE, idempotency, `nhat_ky_bao_mat`): `cap_nhat_thong_tin_truong` (`SCHOOL_PROFILE_UPDATED`) và `dat_logo_truong` (`SCHOOL_LOGO_UPDATED`/`SCHOOL_LOGO_REMOVED`). Khóa lạc quan bằng `phien_ban`; sai phiên bản → `SCHOOL_PROFILE_VERSION_CONFLICT`. Trigger cấm `DELETE`/`TRUNCATE`.
- Logo nằm ở kho đối tượng (`school/logo-<sha256>.<png|jpg>`), bảng chỉ giữ key, content-type, checksum. Chỉ PNG/JPEG, tối đa 1 MB, kiểm bằng magic bytes và kích thước ảnh (không tin đuôi file hay `Content-Type` do client khai). Tên theo nội dung nên tải trùng không tạo file mới; file cũ không bị xóa (có thể dọn bằng quy trình lưu giữ sau).
- API công khai chỉ gồm hai GET: `/school-profile` và `/school-profile/logo` (logo đọc qua `ObjectStorage.get`, không lộ URL MinIO, `Cache-Control: public, max-age=300`). `SessionGuard` cho qua theo tên controller riêng và tên handler, vẫn kiểm `Origin`. Ba thao tác ghi nằm dưới `/admin/school-profile` và bắt buộc phiên QTV cùng `x-idempotency-key`. Hai route công khai không mang `security` trong OpenAPI.

## Đánh đổi

- Dữ liệu công khai gồm điện thoại, email và tên hiệu trưởng nếu QTV nhập; đây là thông tin trường thường công bố, nhưng QTV nên biết khi điền.
- `ma_truong` cố định bằng 1 ở mức này; mọi truy vấn hiện tại đọc thẳng dòng 1.
- Báo cáo Excel bảng điểm chưa in tên trường: thêm dòng phía trên tiêu đề làm lệch vị trí ô mà test và dòng đóng băng/bộ lọc đang dựa vào, nên để dành cho lần làm riêng.

## Hệ quả

Mã lỗi mới `SCHOOL_PROFILE_VERSION_CONFLICT`, `INVALID_SCHOOL_PROFILE` (kèm `details.fields`), `INVALID_LOGO_FILE` (HTTP 409). Client Dart sinh lại từ OpenAPI.
