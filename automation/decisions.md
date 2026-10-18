# Quyết định của chủ dự án

Script `run.py` đưa nguyên file này vào MỌI prompt (cho agent làm, agent sửa và agent review). Đây là nguồn quyết định cao nhất cho đợt "Mẫu bảng điểm", chỉ đứng sau bất biến trong `AGENTS.md`.

**Cách ghi:** mỗi quyết định ghi một mục, có ngày. Không xóa quyết định cũ. Muốn đổi thì thêm mục mới, ghi "thay D-xx".

## Quyết định mở (đang dùng phương án mặc định)

- **D-01 — Xanh cho bảng một kênh.** Mặc định: KHÔNG. Cột chỉ có điểm số thì tối đa Vàng.
- **D-02 — Số trang tối đa mỗi lô.** Mặc định: 4.
- **D-03 — Tự nhận biết mẫu.** Mặc định: chưa làm. Giáo viên luôn chọn mẫu.
- **D-04 — Ngưỡng khớp mẫu `RECOGNITION_TEMPLATE_MIN_SCORE`.** Mặc định: 0,80. Phase P6 được dò lại, chỉ trên DEV.

## Quyết định đã chốt

- 2026-10-18 — Hướng thiết kế theo ADR-0016 (mẫu do QTV khai báo, contract v2, lô nhiều trang nhiều thành phần).

## Trả lời các mục escalate

Khi script dừng vì `BLOCKED`, ghi câu trả lời ở đây theo mẫu bên dưới, rồi chạy lại script.

```
### P?-F? (ngày)
Kết luận: Claude đúng / Reviewer đúng / Làm theo cách khác: ...
Ghi chú: ...
```
