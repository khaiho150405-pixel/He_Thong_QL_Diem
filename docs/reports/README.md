# Báo cáo thực nghiệm của dự án

Thư mục này lưu các báo cáo hoàn chỉnh để đọc, trao đổi và sử dụng trong tài liệu khóa luận.

## Nhận dạng bảng điểm

| Ngày       | Báo cáo                                                                                                           | Phạm vi                                                                                                                                    |
| ---------- | ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 18/10/2026 | [Thử nghiệm Qwen3-VL local](recognition/Bao_cao_thu_nghiem_Qwen3_VL_2026-10-18.docx)                              | 7 trang, 3 biểu đồ, 20 ảnh validation; điều kiện, metrics, kết quả từng ảnh, phân tích lỗi và giới hạn đánh giá                            |
| 18/10/2026 | [So sánh Instruct và Thinking](recognition/So_sanh_Qwen3_VL_Instruct_Thinking_2026-10-18.md)                      | Cùng 20 ảnh, prompt và parser; Instruct hoàn tất 20/20, cột số 9/10, cột chữ 4/10; thời gian và lỗi đối chiếu từng ảnh                     |
| 18/10/2026 | [Đánh giá Qwen fallback trên 200 cặp validation](recognition/Danh_gia_Qwen_fallback_validation_200_2026-10-18.md) | Audit 1.170 nhãn, chạy lại CRNN dot5 + VietOCR Tầng 4 toàn DEV, so Qwen trên cùng 400 crop, mô phỏng fallback và quyết định không tích hợp |

Báo cáo đầu là pilot 20 ảnh. Báo cáo mới so sánh pipeline hiện hành với Qwen trên 200 cặp VALID và đánh giá fallback; chưa chạy TEST/HOLDOUT vì Qwen không cải thiện pipeline nền.

Dữ liệu chi tiết và script của lần thử nằm ngoài repository ứng dụng, tại `F:\HK1_Nam04\KLCN\local-ai\benchmark`. Bản Word ở đây giống nguyên bản đã kiểm tra bố cục; không cần chuyển bộ model hoặc tệp render trung gian vào repository.
