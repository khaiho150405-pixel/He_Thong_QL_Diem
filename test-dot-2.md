# Báo cáo kiểm thử đợt 2

Đợt test này phủ các phần mà `test.md` (đợt 1) chưa kiểm. Kế hoạch: `KE_HOACH_TEST_DOT_2_2026_11_20.md`, nằm ở thư mục KLCN, ngoài repo. Cập nhật: 20/11/2026.

Ký hiệu trạng thái: **Đạt**, **Lỗi → đã sửa**, **Chặn** (do môi trường), **Bỏ qua**, **Không phải lỗi**.

## 1. Cách làm

| Vai                   | Agent                   | Việc                                                                                                                     |
| --------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Điều phối, nghiệm thu | Claude (Opus)           | Đợt 0, giao việc, đọc diff, xem ảnh, kiểm lại giao diện sau khi build lại, chạy gate cuối, commit                        |
| Kiểm thử kỹ thuật     | Codex (GPT-6.1-Sol)     | Bảo mật API, nhận dạng, khóa hạn, tổng kết, tải, vận hành, test tự động. Sau đó nhận thêm phần giao diện bằng Playwright |
| Kiểm thử giao diện    | Antigravity             | Hết credit ngay ở ca đầu, chưa có kết quả; phần việc chuyển sang Codex                                                   |
| Sửa lỗi               | Claude API (Sonnet 5.5) | 4 đợt sửa, kèm test                                                                                                      |

Môi trường:

- Stack thử chạy bằng `scripts/recognition/pilot/up.ps1` trên DB `qld_phase7_test`, có mô hình nhận dạng thật.
- Ca nào đổi trạng thái không quay lại được thì chạy trên bản sao DB `qld_dot2_codex_test` với API riêng ở cổng 3100.
- Test tự động chạy trên DB `quan_ly_diem_test`.
- Không ghi gì lên bản deploy, không dùng `quan_ly_diem_dev`.

Bằng chứng chi tiết (`requestId`, log, ảnh, JSON) nằm ở `.local/dot2/`, ngoài git:

- `report-codex.md`
- `report-codex-ui.md`
- `codex/`, `codex-ui/`, `claude/`
- `claude-api/report-h-c07.md`

## 2. Tổng hợp nhanh

| Nhóm                            | Số ca | Đạt | Lỗi → đã sửa | Chặn | Bỏ qua |
| ------------------------------- | ----: | --: | -----------: | ---: | -----: |
| Bảo mật API (S)                 |    12 |  10 |            1 |    0 |      1 |
| Nhận dạng một ảnh (R)           |    11 |  10 |            1 |    0 |      0 |
| Mẫu bảng điểm, lô (T)           |     5 |   4 |            0 |    0 |      0 |
| Lịch nhập, khóa, điều chỉnh (L) |     6 |   6 |            0 |    0 |      0 |
| Tổng kết, công bố (F)           |     6 |   5 |            1 |    0 |      0 |
| Excel (X)                       |     4 |   2 |            2 |    0 |      0 |
| Lên lớp (Y)                     |     2 |   2 |            0 |    0 |      0 |
| Android, widget (M, W)          |    12 |   0 |            0 |   12 |      0 |
| Hiệu năng (P)                   |     6 |   5 |            0 |    0 |      1 |
| Vận hành (O)                    |     5 |   2 |            0 |    1 |      2 |
| Mô hình nhận dạng (N)           |     4 |   4 |            0 |    0 |      0 |

Ghi chú về bảng:

- T-01 tính là Đạt về chức năng; ghi nhận "không có nút Xóa" được kết luận là không phải lỗi (H-U06).
- S-03 và Y-01 được kết luận là không phải lỗi, nên tính vào cột Đạt (xem H-C02 và H-U08).
- P-01 (đo trên điện thoại thật) được tính vào cột Bỏ qua của nhóm Hiệu năng.

**Không có lỗi P0.**

- 22 lỗi hoặc chênh lệch được ghi nhận.
- 17 lỗi đã sửa và đã nghiệm thu.
- 4 ghi nhận được kết luận là không phải lỗi (kế hoạch đặt kỳ vọng sai).
- 1 lỗi còn lại ở mức P2.

## 3. Lỗi và cách xử lý

| Mã    | Mức | Lỗi                                                                                                  | Trạng thái        | Cách xử lý                                                                                                                                                                                                       |
| ----- | --- | ---------------------------------------------------------------------------------------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| H-01  | P1  | Học sinh thấy điểm tổng kết môn trước khi học kỳ được công bố                                        | Đã sửa            | SQL `studentResults` chỉ trả `finalScore` và `classification` khi `da_cong_bo`; giao diện hiện "Chưa có điểm tổng kết". Đã kiểm bằng API (Codex) và trên web (Claude)                                            |
| B-07  | P2  | Điểm TB học kỳ của học sinh có hai nguồn (client tự tính và API)                                     | Đã sửa            | Thêm `termAverage` và `termClassification` từ API; bỏ `semesterOverviewOf` và `overallClassificationCodeOf` ở client                                                                                             |
| D-08  | P2  | Viết tắt GV/HS không thống nhất                                                                      | Đã sửa            | Đổi sang chữ đầy đủ ở các nhãn tổng quan, báo cáo, thời khóa biểu                                                                                                                                                |
| H-C01 | P2  | Tham số truy vấn ngoài danh sách cho phép vẫn trả 200                                                | Đã sửa            | `apps/api/src/common/query.ts` (`allowQuery`) cho mọi danh sách catalog; trả 400 theo envelope lỗi chuẩn                                                                                                         |
| H-C03 | P2  | AGENTS.md bất biến 13 ghi "ghi 0 mọi ô thiếu", khác ADR-0014 (bổ sung 21/10)                         | Đã sửa (tài liệu) | Câu chữ AGENTS.md khớp hành vi: chỉ cột bắt buộc được ghi 0, cột không bắt buộc giữ NULL                                                                                                                         |
| H-C04 | P1  | Test tích hợp vẫn gọi `POST /gradebooks` đã bị gỡ                                                    | Đã sửa            | Test dùng bảng điểm tự tạo khi phân công                                                                                                                                                                         |
| H-C05 | P1  | `pnpm test:db` có 3 lỗi dữ liệu test; các test chạy song song đụng nhau ở SERIALIZABLE               | Đã sửa            | Chạy tuần tự, loại bảng `phien_ghi_nho` khi đếm, sửa fixture. Đạt 42/42                                                                                                                                          |
| H-C06 | P2  | `pnpm check` dừng ở bước kiểm định dạng                                                              | Đã sửa            | Chạy prettier cho `recognition-checkpoints.md`                                                                                                                                                                   |
| H-C07 | P1  | Tải ghi 12 phiên cùng lúc: p95 khoảng 950 ms                                                         | Không sửa mã      | Nguyên nhân: PostgreSQL hủy và chạy lại giao dịch SERIALIZABLE trên bảng `khoa_idempotency` quá nhỏ, cộng máy đang quá tải. Với dữ liệu cỡ thật p95 còn 166–206 ms. Xem `.local/dot2/claude-api/report-h-c07.md` |
| E-04  | P1  | Hộp thoại thêm học sinh mất khoảng 4 giây (tải mọi trang danh mục)                                   | Đã sửa            | Thêm tham số `limit` (1–500) cho danh sách catalog; hộp thoại giảm từ 26 xuống 2 request                                                                                                                         |
| E-01  | P1  | Màn Giáo viên và phân công gửi quá nhiều request                                                     | Đã sửa            | Giảm từ 16 xuống 5 request danh mục                                                                                                                                                                              |
| H-R01 | P1  | Hồi quy do E-04: hộp thoại chỉ đọc một trang 500 bản ghi, có thể thiếu tài khoản                     | Đã sửa            | Thêm `CatalogRepository.listAll` (tải theo cursor, trang lớn); có test 1200 tài khoản                                                                                                                            |
| H-U01 | P1  | Nhập CSV dùng dấu `;` với điểm `8,5` bị tách lệch cột                                                | Đã sửa            | `grade_import.dart` xác định dấu phân cách từ tiêu đề, hỗ trợ ngoặc kép, dấu phẩy thập phân, BOM                                                                                                                 |
| H-U02 | P1  | File nhập có dòng trùng hoặc điểm ngoài khoảng vẫn cho áp dụng phần hợp lệ                           | Đã sửa            | Báo lỗi theo từng dòng; chặn áp dụng khi còn lỗi hoặc dòng trùng                                                                                                                                                 |
| H-U03 | P2  | File Excel xuất thiếu tên trường                                                                     | Đã sửa            | Thêm dòng tên trường ở đầu sheet, đóng băng 2 dòng                                                                                                                                                               |
| H-U04 | P1  | Màn đối chiếu không hiện giá trị và độ tin cậy từng kênh (bất biến 3)                                | Đã sửa            | Dưới mỗi ảnh ô cắt hiện "Máy đọc … · Tin cậy …%"; với Điểm chữ hiện chữ đọc được và điểm quy đổi. Đã xem trên web                                                                                                |
| H-U05 | P2  | XLSX tạo bằng openpyxl hoặc có ô chuỗi dùng chung gây lỗi `Null check`; CSV mã ANSI báo lỗi kỹ thuật | Sửa một phần      | Đã có thông báo dễ hiểu. Riêng các file đó vẫn chưa đọc được vì lỗi nằm trong thư viện `excel 4.0.6`                                                                                                             |
| H-U07 | P2  | Breadcrumb màn đối chiếu còn "Bảng điểm #13 › Phiếu #10"                                             | Đã sửa            | "Lớp · Môn › Phiếu nhận dạng · thành phần"; bỏ `#id` ở thẻ phiếu, kết quả lô và mẫu                                                                                                                              |
| H-K01 | P2  | Môn Đạt/Không đạt của học sinh hiện nhãn trùng ý "Không đạt · Chưa đạt"                              | Chưa sửa          | Nên chỉ hiện một nhãn                                                                                                                                                                                            |
| H-C02 | —   | S-03: giáo viên được đọc danh mục trong phạm vi được giao                                            | Không phải lỗi    | Chính sách có chủ ý; kế hoạch đặt kỳ vọng sai                                                                                                                                                                    |
| H-U06 | —   | Mẫu bảng điểm không có nút Xóa, chỉ có Ngừng dùng                                                    | Không phải lỗi    | AGENTS.md cấm xóa cứng dữ liệu đã dùng                                                                                                                                                                           |
| H-U08 | —   | Y-01: lên lớp có UPDATE ghi danh cũ                                                                  | Không phải lỗi    | Hàm `xep_lop_nam_moi` chỉ đóng ghi danh đang mở (`DANG_HOC` sang `LEN_LOP`/`LUU_BAN`/`TOT_NGHIEP`, kèm ngày kết thúc) rồi thêm ghi danh mới, đúng ràng buộc `hoc_sinh_lop_dang_hoc_chua_dong`                    |

## 4. Kết quả đáng chú ý

**Gate tự động sau mọi bản sửa** (chạy trên `quan_ly_diem_test`):

| Bước                                                 | Kết quả          |
| ---------------------------------------------------- | ---------------- |
| `pnpm check`                                         | 209/209          |
| `pnpm contracts:check`                               | Đạt              |
| `pnpm test:db`                                       | 42/42            |
| `pnpm test:integration` (`REDIS_URL` trỏ Redis DB 3) | 55/55            |
| Python `unittest`                                    | 269 OK, 3 bỏ qua |
| `flutter analyze`                                    | Sạch             |
| `flutter test`                                       | 740 đạt          |

**Đạt toàn bộ:**

- **Phân quyền và phiên (S-01 → S-11):**
  - Giáo viên không có phân công và học sinh khác không đọc hay sửa được dữ liệu.
  - Nhập sai 5 lần thì khóa 15 phút; giới hạn theo IP trả 429.
  - Token ghi nhớ chỉ dùng một lần; đổi mật khẩu thì thu hồi.
  - Cookie bắt buộc có CSRF; signed URL sống 300 giây; bucket không đọc ẩn danh được.
  - Tên file `../../x.jpg` không thoát khỏi thư mục lưu; ảnh 10001×10001 bị chặn.
  - Log không chứa bí mật.
- **Nhận dạng (R, T):**
  - Duyệt phiếu là giao dịch nguyên tử; gửi phiên bản cũ thì bị chặn mà không ghi dở dữ liệu.
  - Gửi lặp không tạo thêm lịch sử.
  - Sai lớp ra `ROW_MATCH_FAILED`, ảnh trắng hoặc mờ ra `IMAGE_QUALITY_LOW`, sai mẫu ra `TEMPLATE_MISMATCH`.
  - Tắt worker giữa chừng rồi bật lại: tự phục hồi, không tạo job trùng.
  - Đến hạn khi phiếu chưa duyệt thì phiếu chuyển `LOI`.
- **Khóa hạn (L):** trước hạn ô trống vẫn là NULL; đến hạn ghi 0 kèm nhật ký; chạy lại không tạo nhật ký trùng; phiếu điều chỉnh được duyệt và từ chối đúng.
- **Tổng kết (F):** chỉ tính điểm đã duyệt; công bố bị chặn khi chưa đủ điều kiện; ngưỡng Đạt 50%; snapshot giữ phiên bản hệ số.
- **N-04, mô hình T1:** trên tập dev đạt AC-1. Đ.số 99,83%, Điểm chữ 99,49%, gán sai 0, Xanh sai 0; bản v1 là 99,15% và 98,80%.
  - T1 đi kèm CRNN dot6 nên chênh lệch này gồm cả hai thay đổi.
  - Không chạy tập TEST.
- **Test chập chờn (G-04):** `flutter test` chạy 3 lần, mỗi lần 715/715 đạt, không thấy test chập chờn.
- **Build Android (G-01):** APK debug build được bằng JBR của Android Studio với `GRADLE_USER_HOME` trên ổ F; lỗi loopback cũ không còn. Mã Kotlin của widget biên dịch được, xong một phần F-04.

## 5. Còn chặn hoặc chưa làm

| Mục                                                            | Lý do                                                                                                       | Việc cần làm                                                                                      |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| M-01 → M-06, W-01 → W-06 (chạy trên máy ảo)                    | Thư mục máy ảo cũ đã mất, đã tạo lại; máy ảo cần 7,3 GB cho phân vùng dữ liệu nhưng ổ F chỉ còn khoảng 3 GB | Giải phóng ổ F (hoặc cắm điện thoại thật), cài `app-development-debug.apk` rồi chạy các ca M và W |
| O-01 (sao lưu Postgres vận hành)                               | Máy không có `pg_dump`; `docker exec` bị treo khi ổ C gần đầy                                               | Giải phóng ổ C rồi chạy lại `pnpm ops:backup` qua Docker                                          |
| O-04 (cài trên máy mới)                                        | Không có máy mới                                                                                            | Làm khi bàn giao                                                                                  |
| O-05 (tắt lần lượt Postgres, Redis, MinIO, dịch vụ nhận dạng)  | Chưa chạy vì sẽ cắt ngang các agent đang test chung stack                                                   | Chạy khi stack rảnh                                                                               |
| P-01 (màn nhập điểm trên điện thoại thật)                      | Không có thiết bị                                                                                           | Đo trên điện thoại Android tầm trung                                                              |
| F-02, F-03 của `test.md` (widget tự cập nhật khi không mở app) | Cần thiết kế credential chỉ đọc mới                                                                         | Ngoài phạm vi đợt này                                                                             |
| iOS                                                            | Đã dời sang đợt sau theo quyết định ngày 20/11/2026                                                         |                                                                                                   |

**Môi trường:** ổ C có lúc về 0 byte trong đợt test. Đây là lý do worker nhận dạng chung bị chết một lần và Docker client bị treo. Cần dọn ổ C trước đợt test hay buổi demo tiếp theo.

## 6. Dữ liệu thử đã thay đổi

- **`qld_phase7_test`:**
  - Học kỳ 2 năm 2024–2025 đã được khóa và công bố (lớp 10A1).
  - Phân công và bảng điểm 152–154; mẫu `DOT2-UI-P05-EDIT` ở trạng thái Ngừng dùng.
  - Năm học 3 có lớp 17, 18; ghi danh 654–694 do test lên lớp tạo. Năm hiện hành đã được trả về năm của lớp thử BE20.
  - Phiếu 10 vẫn ở trạng thái chờ đối chiếu.
  - Danh sách đầy đủ: `.local/dot2/report-codex-ui.md`, mục "Dữ liệu đã thay đổi".
- **`qld_dot2_codex_test`, `qld_dot2_codex_restore_test`:** bản sao do Codex tạo, giữ lại để đối chiếu; xóa khi không cần nữa.
- **MinIO:** bucket `dot2-codex-restore-test` (358 object) do ca O-01 tạo.
