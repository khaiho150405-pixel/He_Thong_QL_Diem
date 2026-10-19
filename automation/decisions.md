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

### P6-F1 (2026-10-19)

Kết luận: Claude và reviewer đều đúng về phép đo (AC-1 trên DEV KHÔNG ĐẠT: Đ.số 99,15 → 89,74; Điểm chữ 98,80 → 89,32; do 4/60 trang điện thoại mất/dính vạch dọc bị `TEMPLATE_MISMATCH`, 111 dòng). Chủ dự án chọn **phương án 1: mở phạm vi riêng (phase P7)** để cải thiện căn cột khi mất/dính vạch. KHÔNG đổi cách tính AC-1 thành "chỉ dòng đọc được", KHÔNG nới luật "cột cần đọc không ánh xạ → từ chối" theo kiểu đoán.

Với P6: **coi P6-F1 là RESOLVED cho phạm vi P6**. P6 đã làm đúng phần của mình (phép đo đúng, có test chống PASS giả, báo cáo trung thực, mẫu THPT, tài liệu). Yêu cầu không thụt lùi của AC-1 được **chuyển nguyên sang AC-1 của P7** (`automation/phases/P7.md`). Vòng sửa P6 chỉ cần: ghi trong báo cáo `Danh_gia_mau_bang_diem_2026-10-19.md`, ADR-0016 (Kết quả đánh giá) và `CONTINUE.md` một câu "AC-1 chuyển sang P7 theo quyết định chủ dự án 2026-10-19"; không sửa thuật toán, không chạy lại TEST. Reviewer chấm P6-F1 là RESOLVED khi thấy ghi chú này.

### P7-F1, P7-F2 (2026-10-19)

Kết luận: cả hai finding ĐÚNG; nguyên nhân là phiên Claude trước không được cấp quyền đọc `data_dir`. Chủ dự án đã cấp quyền: Claude CLI nay chạy với `--add-dir F:/HK1_Nam04/KLCN/data` (chỉ đọc, không ghi/không đổi tên gì trong đó). KHÔNG chọn phương án "kết thúc phase khi AC-1/AC-5 chờ đo".

Vòng sửa tiếp theo phải làm đúng thứ tự:

1. Chạy các lệnh DEV ở mục 5 báo cáo P7 (`diagnose --split dev --recover`, `run --split dev --layout scripts/recognition/layouts/e0330113.json --tag _v2p7`, `compare --split dev --v2-tag _v2p7`), dùng `.local/venv-ml/Scripts/python.exe`.
2. Nếu AC-1 chưa đạt: chỉ chỉnh thuật toán trên DEV, giữ yêu cầu "vạch thật", giữ nguyên `regression_checks`, rồi đo lại DEV.
3. Khi AC-1 (DEV) ĐẠT: khóa cấu hình, chạy TEST ĐÚNG MỘT LẦN (`run --split test ... --tag _v2p7`, `compare --split test --v2-tag _v2p7`), ghi thời điểm, điền bảng v1/v2-P6/v2-P7 cho DEV và TEST vào báo cáo P7 và ADR-0016.
4. Nếu sau khi chỉnh trên DEV vẫn không đạt AC-1: KHÔNG chạy TEST; ghi số đo DEV thật vào báo cáo và ESCALATE kèm số liệu.
