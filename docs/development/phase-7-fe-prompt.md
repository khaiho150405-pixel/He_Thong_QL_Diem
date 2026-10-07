# Prompt giao Phần B — Frontend cho AI khác (đầy đủ ngữ cảnh)

Dán nguyên khối dưới đây vào AI code Flutter. Prompt tự chứa đủ ngữ cảnh, không bắt buộc AI phải đọc lịch sử trao đổi.

```text
VAI TRÒ
Bạn là lập trình viên Flutter làm PHẦN FRONTEND (FE-01 → FE-05) của "Giai đoạn 7 — Nhận dạng tự động và ghép đúng
học sinh" trong repo He_Thong_QL_Diem (D:\HocTap\KhoaLuan\App\He_Thong_QL_Diem). Backend đã xong; bạn chỉ sửa Flutter.

1. BỐI CẢNH DỰ ÁN
- Hệ thống quản lý điểm trường THPT: QUAN_TRI_VIEN, GIAO_VIEN, HOC_SINH. Monorepo:
  apps/api (NestJS), apps/client_flutter (Flutter web/Android/iOS, Riverpod, GoRouter, Material 3),
  apps/recognition-service (Python FastAPI nhận dạng), packages/api_client_dart (Dart client SINH TỪ OpenAPI).
- Chức năng nhận dạng: giáo viên mở một bảng điểm (lớp–môn–học kỳ), chọn Thành phần điểm, chụp/chọn ảnh tờ bảng điểm
  viết tay rồi gửi. Máy đọc hai kênh Điểm số (CRNN) và Điểm chữ (VietOCR), phân loại Xanh/Vàng/Đỏ. Máy CHỈ ĐỀ XUẤT;
  giáo viên đối chiếu và bấm Duyệt thì điểm mới được ghi chính thức (giao dịch nguyên tử ở backend).
- Lỗi đã sửa ở backend: trước đây dòng thứ n trên ảnh bị gán cho học sinh theo thứ tự mã nên điểm vào nhầm người.
  Nay backend:
  * Tính STT học sinh trong lớp bằng MỘT hàm duy nhất (tên → họ tên → mã) và trả trong API.
  * Khi tạo phiếu, chốt danh sách "STT → học sinh" của lớp; tự xác định dòng thuộc học sinh nào bằng họ tên và
    thứ tự dòng trên giấy; không còn "số dòng khai báo".
  * Trả thêm thông tin ghép dòng và ảnh ô họ tên để giáo viên đối chiếu.
- Mục tiêu chính của chủ dự án: nhận dạng đúng cột ĐIỂM SỐ và ĐIỂM CHỮ, gán đúng học sinh, rồi TỰ CHUYỂN sang một
  MÀN HÌNH KIỂM TRA RIÊNG để giáo viên duyệt. Nhận dạng STT không phải mục tiêu.
- Ràng buộc nghiệp vụ: không thêm/bớt chức năng ngoài sơ đồ (chỉ làm trong các nút 3.2 Tạo lưới điểm theo danh sách
  học sinh; 4.1 Chọn bảng điểm và thành phần; 4.2 Tải ảnh; 5.1–5.8 Đối chiếu và duyệt). Dòng Đỏ không được điền sẵn
  giá trị. Giáo viên phải xem mọi dòng trước khi duyệt. Học sinh không vào được màn hình bảng điểm/nhận dạng.

2. TRƯỚC KHI CODE
- Đọc: AGENTS.md (quy ước chung), docs/ux/ui-control-standard.md, docs/ux/recognition-capture.md,
  docs/adr/0015-recognition-row-matching.md, mục "Việc cho FE" trong docs/development/CONTINUE.md.
- `git branch --show-current` phải là codex/recognition-row-matching. Không tạo nhánh mới, không ghi đè thay đổi
  chưa commit của người khác (nhánh đang có nhiều thay đổi backend chưa commit — để nguyên).
- Flutter 3.35.7 / Dart 3.9.2 (trên máy chủ dự án: C:\src\flutter\bin). Lệnh kiểm tra tại thư mục gốc:
  `dart run melos run check` (format + analyze + test của apps/client_flutter);
  build web: trong apps/client_flutter chạy `flutter build web --dart-define-from-file=config/development.json`.

3. API ĐÃ ĐỔI (dùng qua packages/api_client_dart, KHÔNG sửa tay package này)
- GradeCellDto: thêm `stt` (num?, null khi học sinh đã nghỉ). Các trường cũ giữ nguyên
  (id, studentId, studentName, active, componentId, componentName, value, status, source, openForInput,
  columnLocked, passFail, ...).
- RecognitionApi.recognitionUpload(xIdempotencyKey, gradebookId, image, componentId, int? declaredRows):
  declaredRows nay TÙY CHỌN và deprecated → KHÔNG gửi nữa.
- RecognitionTicketDto (danh sách phiếu) và RecognitionTicketDetailDto (chi tiết): thêm greenRows, yellowRows,
  redRows (num). declaredRows = sĩ số danh sách đã chốt (không phải số giáo viên nhập). detectedRows = số dòng nhận
  dạng. status ∈ DANG_XU_LY | CHO_DOI_CHIEU | DA_DUYET | LOI; errorCode (String?) khi LOI.
  Chi tiết có sourceImageUrl, imageUrlExpiresInSeconds (300), rows.
- RecognitionEvidenceRowDto (từng dòng): rowId, order (vị trí dòng trên ảnh), stt (STT hệ thống, num?),
  sttOnPaper (num?, thường null vì không đọc STT), studentId, studentName (họ tên trong danh sách đã chốt),
  nameRead (String?, họ tên máy đọc), matchConfidence (String? "0.0000"–"1.0000"), matchNote (String?, ghi chú ghép),
  numericRaw/numericValue/numericConfidence, writtenRaw/writtenValue/writtenConfidence,
  comparison ∈ KHOP|LECH|MOT_KENH|KHONG_DOC_DUOC, reviewLevel ∈ XANH|VANG|DO (mức cuối đã gộp điểm + ghép),
  finalValue, numericCropUrl, writtenCropUrl, nameCropUrl (signed URL 300 s). Backend đã sắp dòng theo stt.
- Duyệt: POST .../recognition-tickets/{ticketId}/approve (ReviewApprovalInput: expectedTicketVersion,
  expectedGradebookVersion, decisions[{rowId, value?, reason}]) — GIỮ NGUYÊN logic duyệt hiện có.
- Mã lỗi phiếu (errorCode) cần thông báo tiếng Việt rõ ràng (sửa recognitionFailureMessage trong
  lib/features/recognition/image_preview.dart):
  ROW_MATCH_FAILED: "Không xác định được học sinh cho một số dòng. Kiểm tra đúng lớp và chụp lại rõ cột Họ tên."
  IMAGE_UNREADABLE: "Không đọc được tệp ảnh. Chọn ảnh PNG/JPEG khác."
  IMAGE_QUALITY_LOW: "Ảnh mờ hoặc độ phân giải thấp. Chụp lại gần hơn, đủ sáng, không rung."
  GRID_NOT_FOUND: "Không tìm thấy bảng kẻ ô trong ảnh. Chụp thẳng, đủ toàn bộ bảng."
  NOT_A_GRADEBOOK: "Ảnh không giống bảng điểm. Kiểm tra lại ảnh."
  SCORE_COLUMN_NOT_FOUND: "Không xác định được cột Điểm số/Điểm chữ. Chụp rõ hàng tiêu đề của bảng."
  GRADE_DEADLINE_EXPIRED: "Cột điểm đã hết hạn nhập; phiếu không còn được duyệt."
  Giữ các mã cũ (MODEL_UNAVAILABLE, QUEUE_UNAVAILABLE, MODEL_TIMEOUT), thêm RECOGNITION_TIMEOUT như MODEL_TIMEOUT,
  RECOGNITION_SERVICE_ERROR/MALFORMED_RESPONSE: "Dịch vụ nhận dạng gặp lỗi. Thử lại sau hoặc liên hệ quản trị viên."
  Bỏ thông báo GRID_ROW_COUNT_MISMATCH cũ về "thứ tự dòng" (có thể giữ mã nhưng sửa nội dung cho đúng nghĩa mới).

4. CODE HIỆN TẠI LIÊN QUAN
- lib/app/app.dart: GoRouter (routes /, /login, /gradebooks, /gradebooks/:id, ...); HOC_SINH bị redirect khỏi
  mọi đường dẫn bắt đầu bằng /gradebooks.
- lib/features/gradebooks/gradebook_screen.dart: màn chi tiết bảng điểm. Khoảng dòng 385–400 tự sắp học sinh bằng
  VietnameseCollation.compareStudentNames; cột "STT" (desktop) và "STT n · tên" (mobile) đang dùng chỉ số tự đếm.
  Khoảng dòng 500–520 gắn RecognitionPanel cho giáo viên, truyền declaredRows = số học sinh active.
- lib/features/recognition/recognition_panel.dart: RecognitionPanel (ExpansionTile "Nhận dạng bảng điểm từ ảnh",
  dropdown Thành phần điểm, chụp/chọn ảnh, gửi, polling 3 giây khi có phiếu DANG_XU_LY, danh sách phiếu, hiển thị
  "Số dòng khai báo: N", hướng dẫn "Thứ tự dòng phải trùng danh sách học sinh"); RecognitionDetailDialog
  (~dòng 556–1060): xem ảnh gốc/ảnh ô, hai kênh, lọc màu, nhập giá trị/lý do, xác nhận đã xem mọi dòng, Duyệt.
- lib/features/recognition/repository.dart: list/detail/upload(declaredRows bắt buộc)/approve.
- lib/features/gradebooks/excel_import_dialog.dart: mẫu Excel có cột STT.
- Widget dùng chung: lib/app/widgets/app_controls.dart (AppFilterDropdown, AppActionButton, AppControlMetrics),
  app_scaffold.dart, app_edge_scrollbar.dart.
- Test liên quan: test/phase2_gradebooks_test.dart, phase3_recognition_test.dart, recognition_upload_ux_test.dart,
  grade_deadline_ui_test.dart, phase5_final_results_test.dart, responsive_ui_test.dart. Fixture JSON hiện THIẾU các
  khóa bắt buộc mới (stt; greenRows/yellowRows/redRows; stt/sttOnPaper/nameRead/matchConfidence/matchNote/
  nameCropUrl) nên sẽ lỗi parse — phải bổ sung.

5. CÔNG VIỆC (làm tuần tự, xong mỗi bước chạy kiểm tra rồi mới sang bước sau)

FE-01 — Lưới điểm dùng STT từ API (nút 3.2)
- gradebook_screen.dart: bỏ sắp học sinh bằng VietnameseCollation; sắp theo `stt` từ GradeCellDto, học sinh
  stt == null (đã nghỉ) xếp cuối (giữ thứ tự ổn định theo studentId). Cột STT/nhãn "STT n" hiển thị `stt` từ API
  ("—" khi null). Giữ vietnamese_sort.dart cho các danh sách khác.
- excel_import_dialog.dart: cột STT của mẫu Excel lấy từ `stt` của API.
- Bổ sung khóa "stt" vào mọi fixture ô điểm trong test. Test mới: thứ tự studentId khác thứ tự tên → lưới hiển thị
  đúng theo stt từ API.

FE-02 — Khối nhận dạng: bỏ số dòng khai báo (nút 4.1, 4.2)
- Bỏ tham số declaredRows khỏi RecognitionPanel, gradebook_screen.dart và repository.upload; không gửi declaredRows.
  Khóa idempotency không còn chứa declaredRows.
- Bỏ dòng "Số dòng khai báo: N" và điều kiện chặn khi declaredRows < 1.
- Hướng dẫn mới: "Chụp thẳng toàn bộ bảng, đủ sáng, rõ các cột Họ tên, Điểm số, Điểm chữ. PNG hoặc JPEG, tối đa
  10 MB. Hệ thống tự xác định học sinh theo họ tên."
- Danh sách phiếu: trạng thái CHO_DOI_CHIEU hiển thị "Chờ đối chiếu · N dòng · X Xanh · Y Vàng · Z Đỏ"
  (dùng detectedRows, greenRows, yellowRows, redRows); LOI hiển thị thông điệp mục 3.
- Cập nhật recognitionFailureMessage theo mục 3. Sửa fixture greenRows/yellowRows/redRows. Cập nhật
  recognition_upload_ux_test.dart, phase3_recognition_test.dart.

FE-03 — Màn hình kiểm tra riêng (nút 5.1–5.8)
- Tạo lib/features/recognition/review_screen.dart: chuyển nội dung RecognitionDetailDialog thành màn hình đầy đủ
  (AppScaffold, nút quay lại về bảng điểm), GIỮ NGUYÊN logic: tải chi tiết, làm mới signed URL khi hết hạn mà không
  mất giá trị đang nhập, lọc màu, Đỏ không điền sẵn, bắt buộc xác nhận đã xem mọi dòng (kể cả dòng đang bị lọc),
  gửi approve đúng expectedTicketVersion/expectedGradebookVersion và idempotency, xử lý xung đột 409.
- Route mới trong lib/app/app.dart: /gradebooks/:id/recognition/:ticketId (HOC_SINH bị chặn như /gradebooks).
- Danh sách phiếu trong RecognitionPanel mở màn hình này (context.push) thay cho dialog. Duyệt xong quay về bảng
  điểm và tải lại dữ liệu. Có thể xóa dialog cũ khi không còn dùng.
- Test widget: mở màn hình từ danh sách phiếu; duyệt gửi đúng request; HOC_SINH bị redirect.

FE-04 — Tự chuyển sang màn hình kiểm tra (nút 4.2 → 5.1)
- Sau khi gửi ảnh thành công, ghi nhớ ticketId vừa tạo; polling 3 giây hiện có tiếp tục. Khi phiếu đó chuyển
  CHO_DOI_CHIEU và người dùng VẪN đang ở màn bảng điểm đó → tự điều hướng tới /gradebooks/:id/recognition/:ticketId
  (chỉ một lần). Khi LOI → hiển thị thông điệp theo errorCode và nút "Chụp lại"/"Chọn ảnh khác".
- Trong lúc xử lý hiển thị trạng thái "Đang nhận dạng…" rõ ràng (tiến độ không xác định là đủ).
- Rời màn hình thì dừng polling và không điều hướng.
- Thẻ "OCR chờ duyệt" ở trang chủ giáo viên: chỉ dẫn tới /gradebooks nếu có sẵn dữ liệu; KHÔNG thêm API mới.
- Test widget: DANG_XU_LY → CHO_DOI_CHIEU tự điều hướng; LOI hiển thị lý do; rời màn hình thì không điều hướng.

FE-05 — Hiển thị thông tin ghép học sinh (nút 5.1–5.3)
- Trong review_screen.dart mỗi dòng hiển thị: STT (stt), họ tên hệ thống gán (studentName), ẢNH Ô HỌ TÊN trên giấy
  (nameCropUrl, chạm để phóng to; không có ảnh thì hiện "Không có ảnh"), họ tên máy đọc (nameRead, chữ nhỏ),
  ảnh ô Điểm số và Điểm chữ, giá trị + độ tin cậy hai kênh, matchNote (nếu có), chip màu cuối (reviewLevel).
- Đầu màn hình: tóm tắt N dòng · X Xanh · Y Vàng · Z Đỏ; mặc định hiển thị Vàng/Đỏ trước; bộ lọc 3 màu; trong
  từng nhóm sắp theo stt.
- Nếu matchNote cho thấy nghi lệch học sinh (dòng DO do ghép), làm nổi bật để giáo viên so ảnh họ tên với tên hệ thống.
- Test widget: ảnh họ tên hiển thị; dòng Đỏ không có giá trị gợi ý; lọc màu đúng; responsive.

6. YÊU CẦU GIAO DIỆN
- Tuân theo docs/ux/ui-control-standard.md (control cao 48 px, AppFilterDropdown, AppActionButton).
- Responsive: test ở 320×568, 390×844 và 1280×800 với textScaler 1.3; không overflow. Mobile ưu tiên danh sách
  thẻ dọc; web/desktop có thể dùng bảng.
- Tiếng Việt có dấu đầy đủ. Không hiển thị object key lưu trữ, chỉ dùng signed URL do API trả.
- Không đặt business rule trong widget (không tự tính mức Xanh/Vàng/Đỏ, không tự ghép học sinh) — chỉ hiển thị dữ
  liệu API trả.

7. RÀNG BUỘC
- CHỈ sửa: apps/client_flutter/** (lib, test, integration_test), docs/ux/recognition-capture.md,
  docs/development/CONTINUE.md, docs/development/phase-7-prompts.md (chỉ ô tiến độ FE-01..FE-05).
- KHÔNG sửa: apps/api, database, apps/recognition-service, packages/api_client_dart, scripts. Thiếu trường API →
  DỪNG và báo (ghi trường cần thêm), không tự sửa backend hay client sinh.
- Không commit, push, merge, tạo PR. Không đưa họ tên/ảnh học sinh thật vào test (dùng tên giả như "Học sinh 01").
- Nếu test đỏ không rõ nguyên nhân sau 2 lần sửa → dừng và báo.

8. KẾT THÚC MỖI BƯỚC
- Chạy `dart run melos run check` (bắt buộc) và build web (FE-03 → FE-05). Ghi kết quả thật.
- Thêm mục ở ĐẦU docs/development/CONTINUE.md: "FE-0x — <tên> (xong)": file đổi, hành vi mới, lệnh + kết quả, việc dở.
- Đánh dấu [x] FE-0x trong mục "Tiến độ > Phần B — Frontend" của docs/development/phase-7-prompts.md.
- Sau FE-05: báo cáo tổng hợp tiếng Việt (bước đã xong, file đổi, kết quả kiểm tra, ảnh chụp màn hình nếu có,
  việc còn lại cho backend nếu phát hiện).
```
