# Kiểm kê trọng số nhận dạng — 2026-10-03

Chủ dự án sẽ bổ sung mã huấn luyện/inference và cấu hình sau. Hiện chỉ kiểm kê checkpoint; chưa bật mô hình thật. Không có suy luận giả thay thế trong đường chạy production.

## Đọc thư mục weights

Từ root, trên máy có PyTorch tương thích đã được cài:

```powershell
$env:PYTHONPATH='apps/recognition-service'
python -m src.adapters.checkpoints weights --output .local/recognition-weights-report.json
```

Công cụ đọc `.pth` với `weights_only=True` trên CPU, tính SHA-256, lấy metadata được allowlist và lập danh sách ứng viên. Không có fallback pickle không an toàn; không kích hoạt checkpoint tự động. PyTorch chỉ cần cho công cụ offline này, không thêm vào runtime API hay bộ test CI. Thư mục `/weights/` được Git ignore; báo cáo local cũng không commit.

## Kết quả đọc checkpoint hiện tại

- `crnn_num_best.pth` và `crnn_num_best_dot4.pth` đều báo validation accuracy 99.4872%, CER 0.0022663, epoch 49. Đây là ứng viên có accuracy được ghi cao nhất trong các CRNN hiện có.
- `crnn_num_best_dot5.pth` báo 99.1453%, CER 0.0033994; tên đợt mới hơn không có nghĩa mô hình tốt hơn.
- File có thời điểm sửa local mới nhất là `vietocr_best_tang4_dev.pth`. Timestamp chỉ phản ánh bản sao trên máy, không chứng minh thời điểm huấn luyện.
- Checkpoint VietOCR là state dict, chưa có kiến trúc/config/vocabulary/preprocessing đi kèm đủ để chạy đúng. Các lịch sử huấn luyện dùng tập dữ liệu khác nhau nên không xếp hạng trực tiếp bằng một con số.

Các metric trên do checkpoint cung cấp, chưa được đánh giá độc lập trên bộ ảnh của hệ thống. Không gọi ứng viên này là mô hình tốt nhất đã được kiểm chứng.

## Khi nhận cấu hình bổ sung

1. Xác minh kiến trúc CRNN/VietOCR và hash trọng số; resize, padding, chuẩn hóa, vocabulary, blank index, decoder và phiên bản thư viện.
2. Xác minh tách lưới/ô và thứ tự cột, dữ liệu mẫu hợp lệ; dừng nếu số dòng không khớp khai báo.
3. Chạy cùng một tập kiểm định cho mọi ứng viên; kiểm lỗi, confidence hai kênh và ngưỡng màu trước khi chọn phiên bản.
4. Nối adapter thật vào contract hiện có, thêm test ảnh thực tế/timeout/malformed/model unavailable; giữ xử lý job bất đồng bộ và người duyệt trước khi ghi điểm.

Adapter thật hiện vẫn báo `MODEL_UNAVAILABLE` khi chưa cấu hình. Không triển khai OCR production từ riêng các file trọng số.
