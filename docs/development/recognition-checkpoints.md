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

## Chế độ weights (BE-17 → BE-19, ADR-0015)

Mô hình thật chỉ chạy khi `RECOGNITION_MODEL_MODE=weights` (mặc định) và đủ các biến sau (ba mô hình, mỗi mô hình một tệp + hash), nếu thiếu hoặc sai thì dịch vụ trả `503 MODEL_UNAVAILABLE` và worker không ghi gì:

| Biến                                                              | Ý nghĩa                                                                                                |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `RECOGNITION_CRNN_WEIGHTS` / `RECOGNITION_CRNN_SHA256`            | CRNN đọc ô Đ.số và STT (`crnn_num_best_dot5.pth`)                                                      |
| `RECOGNITION_VIETOCR_WEIGHTS` / `RECOGNITION_VIETOCR_SHA256`      | VietOCR tinh chỉnh đọc ô Điểm chữ (`vietocr_best_tang4.pth`)                                           |
| `RECOGNITION_NAME_WEIGHTS` / `RECOGNITION_NAME_SHA256`            | VietOCR GỐC đọc ô Họ tên in (`vietocr_vgg_seq2seq_pretrained.pth`)                                     |
| `RECOGNITION_NUMERIC_THRESHOLD` / `RECOGNITION_WRITTEN_THRESHOLD` | τ riêng từng kênh của luật hợp nhất (kênh đủ tin cậy ≥ τ), mặc định 0.95 / 0.90 (khóa ở BE-22)         |
| `RECOGNITION_NUMERIC_FLOOR` / `RECOGNITION_WRITTEN_FLOOR`         | mức sàn nhánh đồng thuận, mặc định 0.00 = đúng luật nghiên cứu (khóa ở BE-22 vì DEV không có Xanh sai) |
| `RECOGNITION_DEVICE`                                              | `cpu` (mặc định) hoặc `cuda`                                                                           |

Cài phụ thuộc mô hình: `pip install -e apps/recognition-service[ml]` (torch, torchvision; nhóm tùy chọn, CI và chế độ fake không cần) rồi `pip install --no-deps vietocr==0.3.13`. Không có torch thì chế độ weights trả `MODEL_UNAVAILABLE` và các bài test cần torch tự bỏ qua.

Cột Họ tên (BE-20b): họ tên trên mẫu là chữ IN, còn `vietocr_best_tang4.pth` được tinh chỉnh cho điểm chữ viết tay nên đọc tên in kém; cột Họ tên dùng bản VietOCR gốc `vgg_seq2seq` (tệp tải MỘT LẦN từ `https://vocr.vn/data/vietocr/vgg_seq2seq.pth` về `D:\HocTap\KhoaLuan\App\weights\vietocr_vgg_seq2seq_pretrained.pth`, SHA-256 `0921503a41375a0584268e23ef3d414ea478a8fe8777865c7745d38f2d0bc5db`; dịch vụ không tải gì lúc chạy). Thiếu cấu hình mô hình tên thì `MODEL_UNAVAILABLE`; không bao giờ tự dùng mô hình điểm chữ thay thế. Ô họ tên của mẫu gồm hai cột con (họ đệm | tên) cách nhau khe trắng rộng; mô hình đọc chuỗi dừng ở khe nên mất phần tên, vì vậy `rows.compact_name_cell` thu khe rộng hơn một chiều cao ô về 0,4 chiều cao (chỉ ghép lại mực gốc) trước khi đọc và lưu ảnh ô.

Cột STT không được nhận dạng (quyết định của chủ dự án): dịch vụ luôn trả `stt.value = null`, `stt.confidence = 0`; ghép dòng dựa vào họ tên và thứ tự.

Quy tắc an toàn: SHA-256 được kiểm trước khi nạp; trọng số chỉ nạp bằng `torch.load(weights_only=True)` (không nạp được thì `MODEL_UNAVAILABLE`, không hạ sang pickle tùy ý); cấu hình VietOCR (`src/adapters/vietocr_vgg_seq2seq.yml`) đã loại mọi URL tải mô hình; không tải gì từ Internet lúc chạy. `vietocr==0.3.13` phải cài `pip install --no-deps vietocr==0.3.13` (cùng `einops`), vì các phụ thuộc của nó không cần cho suy luận. Dùng `crnn_num_best_dot5.pth` và `vietocr_best_tang4.pth`, không dùng bản `*_dev.pth` (chỉ để dò ngưỡng). `modelVersion` = `crnn-dot5+vietocr-tang4+name-vgg:<12 ký tự đầu của SHA-256 ghép ba hash>`.

Ảnh bị từ chối trả `422` với `{"detail": {"code", "message"}}`, mã ổn định: `IMAGE_UNREADABLE`, `IMAGE_QUALITY_LOW`, `GRID_NOT_FOUND`, `NOT_A_GRADEBOOK`, `SCORE_COLUMN_NOT_FOUND`; worker đánh dấu phiếu `LOI` đúng mã, không thử lại.

Đã thử local (dữ liệu huấn luyện, chỉ để kiểm tra đường chạy, không phải đánh giá độc lập): hai trọng số nạp được bằng chế độ an toàn; ~4 giây/ảnh trên CPU. Việc dò ngưỡng và đánh giá trên ảnh cấp 3 thật thuộc BE-21–BE-22.
