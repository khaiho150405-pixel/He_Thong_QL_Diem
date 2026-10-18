# Đánh giá Qwen Instruct và fallback trên validation

Ngày chạy: 18/10/2026. Mục tiêu là quyết định Qwen3-VL Instruct có cải thiện được CRNN dot5 + VietOCR Tầng 4 khi nhận dạng bảng điểm viết tay hay không.

## Kết luận

Không đưa Qwen vào luồng nhận dạng hoặc fallback điểm hiện tại. Trên cùng 200 cặp validation, pipeline hiện hành đúng 198/200 điểm số và 199/200 điểm chữ; Qwen Instruct đúng 180/200 và 85/200. Trong mẫu, Qwen sửa được 1 lỗi số nhưng tạo thêm nhiều lỗi; Qwen không sửa được lỗi chữ nào của pipeline. Các ngưỡng fallback đã định trước không tăng số đúng. Qwen cũng không giải quyết được dòng bất đồng: hai ảnh Qwen cùng cho một giá trị ở 0/3 dòng nền bất đồng.

Vì không có phương án Qwen nào tốt hơn trên validation, bước 5 dừng ở quyết định giữ pipeline hiện hành. **Không chạy TEST hoặc HOLDOUT** và không tích hợp Qwen. Tập TEST còn nguyên cho một ứng viên được chọn ở validation trong tương lai.

## 1. Kiểm tra nhãn và ảnh

Đã kiểm tra toàn vẹn manifest chuẩn, ảnh, cặp số–chữ, nhãn rỗng, giá trị có thể phân tích và sự đồng thuận hai nhãn. Không sửa dữ liệu nguồn.

| Kiểm tra | Kết quả |
|---|---:|
| Số ô số / ô chữ | 1.170 / 1.170 |
| Cặp số–chữ ghép được | 1.170/1.170 |
| Thiếu ảnh, đường dẫn trùng, nhãn rỗng | 0 |
| Nhãn không phân tích được / cặp nhãn lệch điểm | 0 / 0 |
| Phân bố | P05: 380; R03: 410; T03: 380; phone/scan: 585/585; NORMAL/VARIANT: 1.052/118 |

Đây là kiểm tra tự động theo manifest và parser. Nó không thay thế việc xem lại ảnh nguồn cho mục đích sửa nhãn thủ công.

## 2. Bộ validation mở rộng

Đã khóa 200 cặp (400 ảnh) từ VALID. Mẫu gồm 116 cặp `VARIANT` và 84 `NORMAL`; phân bố ba người viết là 67/67/66, nguồn phone/scan là 101/99. Các cặp pilot cũ và một ảnh chỉ dùng để chẩn đoán lỗi API bị loại khỏi lượt đo. Instruct nhận từng crop riêng, không thấy nhãn hoặc dự đoán CRNN/VietOCR.

Mẫu lấy gần hết ảnh `VARIANT`, vì vậy accuracy thô trên 200 cặp không đại diện cho tỷ lệ NORMAL/VARIANT của toàn validation. Báo cáo nêu kết quả từng nhóm và ước lượng Qwen có trọng số theo manifest. Validation chỉ có ba người viết, nên không khẳng định kết quả cho giáo viên mới.

## 3. Pipeline hiện hành chạy lại trên cùng dữ liệu

Đã chạy lại mô hình hiện hành trên toàn bộ 60 ảnh trang DEV, đối chiếu đủ 1.170 nhãn. Checkpoint: `crnn-dot5+vietocr-tang4+name-vgg:1f230266bd93`.

| Chỉ số toàn VALID | Kết quả |
|---|---:|
| Điểm số CRNN đúng | 1.160/1.170 = 99,1% |
| Điểm chữ VietOCR đúng | 1.156/1.170 = 98,8% |
| Giá trị cuối đúng theo luật nghiên cứu | 99,2% |
| Xanh / Vàng / Đỏ | 1.146 / 17 / 7 |
| Xanh sai | 0 |
| Thời gian trang | trung vị 1,6 giây; lớn nhất 4,5 giây |

So sánh từng crop trong mẫu Qwen cũng lấy đầu ra CRNN/VietOCR từ chính lần chạy toàn trang này, không dùng các CSV dot4/VietOCR gốc của pilot trước.

## 4. Qwen và các quy tắc fallback

Model `qwen3-vl:instruct-8b-q4km-20261018` (8B, Q4_K_M), Ollama 0.40.5. Giữ prompt/schema/parser của pilot Instruct, `temperature=0`, `seed=7`, `num_ctx=2048`, `num_predict=512`, `think=false`; mỗi yêu cầu chỉ nhận một ảnh gốc. Parser SHA-256: `6a72b785b168ddd7e5b0a2f9847e85fe31aacde0d4694632e5107229fece42f2`. Lượt chính hoàn tất 400/400 đầu ra JSON, không có lỗi API. Lần thử đầu gặp HTTP 500 và một yêu cầu chẩn đoán được loại khỏi mẫu đo.

| Kênh trên cùng 200 ô | Pipeline hiện hành | Qwen | Đúng cả hai | Chỉ pipeline đúng | Chỉ Qwen đúng |
|---|---:|---:|---:|---:|---:|
| Điểm số | 198/200 (99,0%) | 180/200 (90,0%) | 179 | 19 | 1 |
| Điểm chữ | 199/200 (99,5%) | 85/200 (42,5%) | 85 | 114 | 0 |

Ước lượng Qwen có trọng số theo phân bố manifest là 93,0% cho điểm số và 41,8% cho điểm chữ; so với phép chạy chính xác toàn validation của pipeline là 99,1% và 98,8%. Ước lượng này dựa trên mẫu con, không phải một lần chạy Qwen toàn bộ 1.170 cặp.

| Fallback chỉ thay ô khi confidence nền thấp hơn | Số ô gọi Qwen | Điểm số đúng sau fallback | Điểm chữ đúng sau fallback |
|---|---:|---:|---:|
| `< 0,85` | 1 số / 3 chữ | 198/200 | 199/200 |
| `< 0,90` | 10 số / 35 chữ | 198/200 | 199/200 |
| `< 0,95` | 22 số / 85 chữ | 197/200 | 199/200 |
| `< 0,98` | 38 số / 85 chữ | 196/200 | 199/200 |
| `< 0,99` | 45 số / 85 chữ | 196/200 | 199/200 |

Ngưỡng thấp không cải thiện số đúng; ngưỡng cao làm giảm độ đúng điểm số. Với kênh chữ, Qwen không sửa được lỗi baseline nào trong mẫu. Quy tắc yêu cầu hai kênh Qwen đồng thuận khi hai kênh nền bất đồng cũng không có trường hợp đồng thuận nào trong 3 dòng nền bất đồng.

Nhóm chữ `VARIANT` là điểm yếu rõ nhất: Qwen đúng 27/116 (23,3%); ở nhóm `NORMAL`, đúng 58/84 (69,0%). Kết quả thay đổi nhiều theo người viết:

| Người viết | NORMAL đúng | VARIANT đúng |
|---|---:|---:|
| P05 | 2/7 (28,6%) | 15/60 (25,0%) |
| R03 | 55/67 (82,1%) | không có mẫu VARIANT |
| T03 | 1/10 (10,0%) | 12/56 (21,4%) |

P05/T03 chỉ có 7/10 ảnh NORMAL mỗi người trong mẫu, nên các tỷ lệ nhỏ này còn dao động mạnh. Chênh lệch giữa người viết cho thấy không thể suy ra hiệu quả cho giáo viên mới từ một tỷ lệ gộp. Cả hai mức NORMAL/VARIANT đều thấp hơn đáng kể pipeline hiện hành.

## Tốc độ và tài nguyên

| Chỉ số Qwen Instruct | Kết quả |
|---|---:|
| Tổng thời gian 400 yêu cầu | 2.746,74 giây (45 phút 47 giây) |
| Trung vị / p95 mỗi crop | 6,65 / 8,00 giây |
| Đỉnh VRAM lấy mẫu toàn GPU | 3.193/4.096 MiB |
| Đỉnh RAM lấy mẫu toàn máy | 16.055/16.069 MiB |

RAM/VRAM là mức toàn máy/toàn GPU lấy mẫu, không thể quy hoàn toàn cho model. Tuy vậy, mức sử dụng RAM cao và tốc độ từng crop cho thấy gọi Qwen trên nhiều ô sẽ tăng đáng kể thời gian xử lý.

Model đã được nạp trong yêu cầu chẩn đoán trước lượt chính (load khoảng 13 giây); thời gian 45 phút 47 giây và p50/p95 ở trên đo khi model đã nóng, không gồm khởi động lạnh.

## 5. Quyết định và hành động tiếp theo

- Giữ CRNN dot5 + VietOCR Tầng 4 làm pipeline; không dùng Qwen để thay điểm hoặc làm fallback theo các ngưỡng đã thử.
- Không chạy TEST/HOLDOUT cho Qwen vì validation chưa tìm được ứng viên có cải thiện. Không sửa mã nghiệp vụ.
- Tập trung kiểm tra 10 lỗi số và 14 lỗi chữ trong lần chạy DEV toàn tập; chia theo người viết, kiểu ảnh và confidence để tìm nguyên nhân cụ thể.
- Nếu tiếp tục nghiên cứu Qwen, cần thay đổi có cơ sở (ví dụ fine-tune nhận dạng chữ viết tay hoặc tạo vùng crop phù hợp hơn), sau đó đánh giá lại trên validation khóa mới trước khi cân nhắc TEST.
- Muốn tuyên bố khả năng dùng cho giáo viên thực tế, bổ sung ảnh từ người viết mới và đo cả thời gian duyệt của giáo viên; VALID hiện tại chỉ gồm P05/R03/T03.

## Tệp và khả năng tái lập

- [Kiểm toán 1.170 cặp nhãn và hash ảnh](../../../../local-ai/benchmark/results/2026-10-18-validation-audit/summary.json) và [CSV từng cặp](../../../../local-ai/benchmark/results/2026-10-18-validation-audit/paired_labels_audit.csv).
- [Giao thức được khóa trước khi đọc kết quả tổng hợp](../../../../local-ai/benchmark/results/2026-10-18-validation-200-instruct-02/PROTOCOL.md).
- [Tóm tắt metrics Qwen](../../../../local-ai/benchmark/results/2026-10-18-validation-200-instruct-02/summary.json), [đối chiếu từng ô](../../../../local-ai/benchmark/results/2026-10-18-validation-200-instruct-02/paired_comparison.csv), [metadata](../../../../local-ai/benchmark/results/2026-10-18-validation-200-instruct-02/metadata.json), [danh sách mẫu](../../../../local-ai/benchmark/results/2026-10-18-validation-200-instruct-02/selection.json) và phản hồi gốc `response_001.json`–`response_400.json` trong cùng thư mục.
- [Cache lần chạy pipeline toàn DEV](../../../../He_Thong_QL_Diem/.local/eval/dev_qwenfollowup_20261018.json).
- Scripts: `local-ai/benchmark/audit_validation.py`, `validation_qwen.py`, `compare_validation.py`; lệnh chạy nằm trong `local-ai/benchmark/README.md`.
