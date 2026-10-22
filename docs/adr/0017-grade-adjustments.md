# ADR-0017: Điều chỉnh điểm sau chốt

- Trạng thái: chấp nhận (2026-10-22)
- Liên quan: bất biến 8, 11, 13 trong `AGENTS.md`; ADR-0014 (hạn nhập điểm, ô Miễn)

## Vấn đề

Cột hết hạn bị khóa vĩnh viễn (`chot_cot_diem` append-only, trigger `kiem_cot_diem`). Nhập nhầm, phúc khảo, thi bù chỉ sửa được bằng sửa thẳng DB nên mất truy vết.

## Quyết định

- **Phiếu điều chỉnh theo bảng điểm** (`phieu_dieu_chinh` + `dong_dieu_chinh`, bất biến sau khi tạo). Giáo viên phụ trách gửi 1–100 ô, lý do chung 1–500 ký tự, ghi chú từng ô tùy chọn (≤200). Chỉ ô thuộc cột đã chốt (`CELL_NOT_LOCKED` nếu cột còn mở). Mỗi dòng: đổi giá trị 0.0–10.0 (môn Đạt/Không đạt chỉ 0.0/10.0), đặt Miễn, hoặc bỏ Miễn kèm giá trị mới; không đổi thành trống. Dòng không đổi bị bỏ; phiếu rỗng → `ADJUSTMENT_NO_CHANGE`.
- Mỗi bảng chỉ có một phiếu `CHO_DUYET`. Trạng thái: `CHO_DUYET → DA_DUYET | TU_CHOI` (QTV, từ chối bắt buộc lý do) `| DA_HUY` (người gửi tự hủy). Học kỳ đã công bố: không gửi, không duyệt (`TERM_ALREADY_PUBLISHED`).
- QTV duyệt cả phiếu trong một giao dịch SERIALIZABLE: mọi ô phải còn đúng giá trị/trạng thái đã lưu khi gửi, nếu không `ADJUSTMENT_STALE` và rollback toàn bộ; ghi điểm mới, thêm `lich_su_sua_diem` (người sửa là giáo viên gửi; lý do "Điều chỉnh sau chốt #mã: lý do chung[; ghi chú] — duyệt bởi tên QTV"), ghi `lich_su_mien_diem` khi đổi Miễn, đặt `bang_diem.can_tinh_lai_tong_ket`, tăng version bảng.
- Cột đã chốt vẫn chỉ ghi được qua đường này: `duyet_phieu_dieu_chinh` đặt cờ giao dịch cục bộ `qld.dieu_chinh_sau_chot` = mã phiếu; trigger `kiem_cot_diem` chỉ cho UPDATE ô cột đã chốt khi cờ trỏ tới phiếu `CHO_DUYET` có dòng cho đúng ô đó với đúng giá trị/trạng thái mới. Runtime không có quyền UPDATE trực tiếp bảng điểm; cờ giả không cho ghi giá trị nào ngoài phiếu.
- Sau điều chỉnh, kết quả tổng kết lỗi thời: `tinh_ket_qua_bang_diem` đặt lại cờ khi tính xong; `kiem_san_sang_cong_bo` báo `RESULTS_OUTDATED` (BLOCKING) cho đến khi tính lại.
- Vá (migration `202610220002`): `cap_nhat_diem` tự chặn ô cột đã chốt (`COLUMN_LOCKED`) không phụ thuộc trigger, nên cờ giao dịch chỉ còn tác dụng với `duyet_phieu_dieu_chinh`; bảng còn phiếu `CHO_DUYET` làm `kiem_san_sang_cong_bo` báo `ADJUSTMENT_PENDING` (BLOCKING) và công bố bị `TERM_RESULTS_INCOMPLETE`.

## Hệ quả

Mọi sửa điểm sau chốt có người gửi, người duyệt, lý do và giá trị cũ/mới. Không có đường xóa phiếu hay dòng. Phiếu đang chờ chặn công bố; duyệt hoặc hủy phiếu trước.
