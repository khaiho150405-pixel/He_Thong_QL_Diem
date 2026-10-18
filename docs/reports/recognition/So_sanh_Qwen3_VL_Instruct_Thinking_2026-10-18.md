# So sánh Qwen3 VL Instruct và Thinking trên validation

Ngày thực hiện: 18/10/2026. Cùng 20 ảnh (10 cặp số–chữ), P05/R03/T03; chưa chạy TEST hoặc HOLDOUT.

## Điều kiện giữ nguyên

Cùng ảnh và nhãn có SHA256, thứ tự, prompt, JSON schema, parser, Ollama 0.40.5, temperature=0, seed=7, num_ctx=2048, num_predict=512, think=false. Mỗi yêu cầu chỉ có một ảnh, không truyền lịch sử hoặc dự đoán mô hình khác. Không sửa parser hay nắn chữ theo từ điển sau khi xem kết quả.

Thinking: `qwen3-vl:snapshot-20261017`. Instruct: `qwen3-vl:instruct-8b-q4km-20261018`. Cả hai là 8B (API ghi 8,8B), Q4_K_M.

## Kết quả

| Chỉ số | Thinking | Instruct |
|---|---:|---:|
| Đúng giá trị cột số | 9/10 | 9/10 |
| Đúng giá trị cột chữ | 0/10 | 4/10 |
| Đúng cả cặp | 0/10 | 4/10 |
| JSON hợp lệ và hoàn tất | 14/20 | 20/20 |
| Hết token trước đáp án cuối | 6 | 0 |
| Phản hồi có thinking | 20 | 0 |
| Tổng token sinh | 6254 | 424 |
| Tổng thời gian yêu cầu (giây) | 1201,63 | 129,51 |
| p50 sau lượt đầu (giây) | 58,45 | 6,38 |
| p95 sau lượt đầu (giây) | 99,76 | 6,75 |
| Trung bình ô số (giây) | 32,52 | 6,49 |
| Trung bình ô chữ (giây) | 87,64 | 6,47 |
| Đỉnh VRAM toàn GPU lấy mẫu (MiB) | 3153,00 | 3193,00 |
| Đỉnh RAM toàn máy lấy mẫu (MiB) | 15920,93 | 15881,56 |

Số ảnh đổi từ sai sang đúng: **4**; từ đúng thành sai: **0** (so theo giá trị qua cùng parser).

## Nhận định từ lượt thử

Instruct hoàn tất 20/20 đầu ra, có 0 phản hồi sinh thinking và 0 lỗi hết token. Cột chữ đạt 4/10 so với 0/10 của Thinking. Đây là cải thiện về vận hành trong điều kiện quan sát, chưa đủ để thay hệ nhận dạng hiện tại.
Các lỗi chữ còn thấy gồm “ba tám” → “ba ta'm”, “sáu chẵn” → “Sau chén”, “tám chẵn” → “tâm chấn”. Vì vậy, trả được JSON nhanh không đồng nghĩa đã nhận dạng đúng. Giữ CRNN/VietOCR làm mốc và tiếp tục kiểm chứng trên validation trước khi tích hợp.

## Cách đọc kết quả

Độ đúng này đo model cộng parser trên nhãn manifest, không phải OCR thuần. Ví dụ ảnh cột số viết “Sáu” nhưng nhãn là 6.0: chép đúng “Sáu” vẫn bị parser số từ chối. Lỗi hết token/định dạng được giữ trong mẫu số; không dùng phần thinking làm đáp án.

Instruct được nạp riêng trước khi đo ảnh: 12,39 giây. Thinking lượt 02 đã được nạp bởi lượt 01. p50/p95 so 19 yêu cầu sau yêu cầu đầu; không phải benchmark 20 warm-up chuẩn. Hai lượt chạy khác thời điểm nên bộ nhớ trống, chương trình nền và mức offload có thể khác; tốc độ chỉ mô tả hai lượt quan sát, chưa chứng minh chênh lệch do riêng biến thể.

RAM/VRAM lấy mẫu toàn máy/toàn GPU, không phải riêng model. Tổng thời gian yêu cầu không bao gồm tải model, thời gian nạp tách riêng hoặc khoảng dừng giữa các lần chạy.

## Từng ảnh

| Cặp | Cột | Nhãn | Thinking | Instruct |
|---:|---|---|---|---|
| 1 | num | 3.8 | 3.8 | 3.8 |
| 1 | txt | ba tám | ba to' | ba ta'm |
| 2 | num | 6.0 | Sáu | Sau |
| 2 | txt | sáu chẵn | Lỗi đầu ra | Sau chén |
| 3 | num | 7.0 | 7.0 | 7.0 |
| 3 | txt | bảy không | Lỗi đầu ra | bài không |
| 4 | num | 8.0 | 8.0 | 8,0 |
| 4 | txt | tám chẵn | Lỗi đầu ra | tâm chấn |
| 5 | num | 5.0 | 5.0 | 5.0 |
| 5 | txt | năm chẵn | năm chăn | năm chẵn |
| 6 | num | 3.1 | 3.1 | 3.1 |
| 6 | txt | ba một | ba môt | ba một |
| 7 | num | 3.1 | 3.1 | 3.1 |
| 7 | txt | ba một | ba mặt | ba mặt |
| 8 | num | 6.8 | 6.8 | 6.8 |
| 8 | txt | sáu tám | Lỗi đầu ra | Sáu tám |
| 9 | num | 7.9 | 7.9 | 7.9 |
| 9 | txt | bảy chín | Lỗi đầu ra | bảy chín |
| 10 | num | 6.1 | 6.1 | 6.1 |
| 10 | txt | sáu một | Lỗi đầu ra | sau mỗi |

## Giới hạn và bước tiếp

Đây là pilot 10 cặp, không đủ kết luận tổng quát hóa cho giáo viên mới hoặc độ chính xác TEST. Chưa đánh giá hệ kết hợp với CRNN/VietOCR, ô trống, phát hiện mâu thuẫn, nhóm Xanh, đọc nguyên bảng hay thời gian giáo viên duyệt.
Nếu Instruct cải thiện, bước tiếp là bộ validation lớn hơn có trường hợp khó và chuẩn hóa nhãn/bản chép riêng. Chỉ chốt prompt và quy tắc kết hợp trên validation rồi mới đo TEST.

## Tệp đối chiếu

Thư mục kết quả: `F:\HK1_Nam04\KLCN\local-ai\benchmark\results\2026-10-18-instruct-01`.
- `metadata.json`, `selection.json`, `response_*.json`: điều kiện và phản hồi gốc.
- `predictions.csv`, `summary.json`, `memory_samples.json`: dự đoán, metrics và tài nguyên.
- `comparison_thinking_instruct.csv`, `variant_comparison.json`: so sánh theo đúng từng ảnh.
- `pilot_qwen_source.py`: mã runner thực tế.
