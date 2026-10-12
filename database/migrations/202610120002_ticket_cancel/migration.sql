-- Hủy mềm phiếu nhận dạng (ADR-0015): phiếu không bao giờ bị xóa; chuyển sang trạng thái DA_HUY kèm người, thời điểm, lý do.
-- Giá trị enum DA_HUY được thêm ở 202610120001_ticket_cancel_enum (phải commit trước khi dùng).
--
--  - phieu_nhan_dien: thêm ly_do_huy, nguoi_huy, thoi_diem_huy; CHECK để ba cột này có đủ khi và chỉ khi trang_thai = 'DA_HUY'.
--  - ma_bam_tep: bỏ UNIQUE toàn bảng, thay bằng UNIQUE một phần (WHERE trang_thai <> 'DA_HUY'); hủy xong tải lại đúng ảnh được.
--  - tao_phieu_nhan_dien: DUPLICATE_FILE chỉ xét phiếu chưa hủy. Các điều kiện "đang chờ" (DANG_XU_LY/CHO_DOI_CHIEU) ở chốt cột,
--    lịch nhập điểm, job hạn nhập, đồng bộ sĩ số đều là danh sách dương nên DA_HUY không bị tính là phiếu chờ và không bị
--    chuyển trạng thái nhầm; không cần sửa các hàm đó.
--  - luu_ket_qua_nhan_dien: phiếu DA_HUY thì RETURN, không ghi gì (worker có thể đang xử lý lúc phiếu bị hủy).
--  - huy_phieu_nhan_dien: hàm mới theo khuôn mẫu duyet_phieu_nhan_dien (phiên, quyền, idempotency, version, audit).
--
-- ROLLBACK (chỉ tiến khi đã có phiếu DA_HUY): các phiếu DA_HUY là bằng chứng, không xóa. Nếu chưa có phiếu DA_HUY thì có thể
-- DROP FUNCTION huy_phieu_nhan_dien, khôi phục hai hàm tao_phieu_nhan_dien (202610060002) và luu_ket_qua_nhan_dien
-- (202610100001), DROP INDEX phieu_nhan_dien_ma_bam_tep_active_key rồi
-- CREATE UNIQUE INDEX phieu_nhan_dien_ma_bam_tep_key ON phieu_nhan_dien(ma_bam_tep), cuối cùng DROP CONSTRAINT
-- phieu_huy_day_du, phieu_huy_ly_do và DROP COLUMN ly_do_huy, nguoi_huy, thoi_diem_huy.
BEGIN;

ALTER TABLE public.phieu_nhan_dien
  ADD COLUMN ly_do_huy varchar(200),
  ADD COLUMN nguoi_huy integer REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ADD COLUMN thoi_diem_huy timestamptz(6),
  ADD CONSTRAINT phieu_huy_day_du CHECK (
    (trang_thai = 'DA_HUY') = (ly_do_huy IS NOT NULL AND nguoi_huy IS NOT NULL AND thoi_diem_huy IS NOT NULL)
  ),
  ADD CONSTRAINT phieu_huy_ly_do CHECK (ly_do_huy IS NULL OR length(btrim(ly_do_huy)) > 0);
CREATE INDEX phieu_nhan_dien_nguoi_huy_idx ON public.phieu_nhan_dien(nguoi_huy) WHERE nguoi_huy IS NOT NULL;

DROP INDEX public.phieu_nhan_dien_ma_bam_tep_key;
CREATE UNIQUE INDEX phieu_nhan_dien_ma_bam_tep_active_key
  ON public.phieu_nhan_dien(ma_bam_tep) WHERE trang_thai <> 'DA_HUY';

CREATE OR REPLACE FUNCTION public.tao_phieu_nhan_dien(
  p_phien text,
  p_book integer,
  p_component integer,
  p_checksum text,
  p_object_key text,
  p_roster jsonb,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  actor_id integer;
  active_rows integer;
  roster_rows integer;
  ticket_id bigint;
  prior public.khoa_idempotency;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_checksum !~ '^[0-9a-f]{64}$' OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR p_object_key !~ '^recognition/original/[0-9a-f-]{36}[.](png|jpg)$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_RECOGNITION_REQUEST' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s
  JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO b FROM public.bang_diem
  WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF b.trang_thai <> 'DANG_NHAP_LIEU'
     OR NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
       WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
         AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky)
     OR NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem tp
       WHERE tp.ma_thanh_phan=p_component AND tp.ma_mon=b.ma_mon) THEN
    RAISE EXCEPTION 'FORBIDDEN_OR_STATE_CONFLICT' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_UPLOAD'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  -- Hình dạng snapshot: mảng 1..2000 object đúng ba khóa {stt, studentId, fullName}.
  IF p_roster IS NULL OR jsonb_typeof(p_roster) <> 'array'
     OR jsonb_array_length(p_roster) NOT BETWEEN 1 AND 2000
     OR EXISTS (
       SELECT 1 FROM jsonb_array_elements(p_roster) e
       WHERE jsonb_typeof(e) <> 'object'
         OR (SELECT count(*) FROM jsonb_object_keys(e)) <> 3
         OR NOT (e ?& ARRAY['stt','studentId','fullName'])
         OR jsonb_typeof(e->'stt') <> 'number'
         OR jsonb_typeof(e->'studentId') <> 'number'
         OR jsonb_typeof(e->'fullName') <> 'string'
         OR (e->>'stt') !~ '^[1-9][0-9]{0,8}$'
         OR (e->>'studentId') !~ '^[1-9][0-9]{0,8}$'
         OR length(e->>'fullName') NOT BETWEEN 1 AND 100
     ) THEN
    RAISE EXCEPTION 'INVALID_ROSTER_SNAPSHOT' USING ERRCODE='23514';
  END IF;
  roster_rows := jsonb_array_length(p_roster);
  SELECT count(*)::integer INTO active_rows FROM public.hoc_sinh
  WHERE ma_lop=b.ma_lop AND dang_theo_hoc;
  -- n = sĩ số đang học; STT liên tục 1..n không trùng; học sinh không trùng, thuộc lớp, đang học, đúng họ tên.
  IF roster_rows <> active_rows
     OR (SELECT count(DISTINCT (e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT min((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> 1
     OR (SELECT max((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(DISTINCT (e->>'studentId')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(*) FROM jsonb_array_elements(p_roster) e
         JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh=(e->>'studentId')::integer
          AND hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND hs.ho_ten=(e->>'fullName')) <> roster_rows THEN
    RAISE EXCEPTION 'INVALID_ROSTER_SNAPSHOT' USING ERRCODE='23514';
  END IF;

  -- Chỉ phiếu chưa hủy mới chặn tải lại cùng ảnh (hủy xong tải lại đúng ảnh được).
  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien
    WHERE ma_bam_tep=p_checksum AND trang_thai <> 'DA_HUY') THEN
    RAISE EXCEPTION 'DUPLICATE_FILE' USING ERRCODE='23505';
  END IF;
  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien
    WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component
      AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
    RAISE EXCEPTION 'RECOGNITION_ALREADY_PENDING' USING ERRCODE='23514';
  END IF;

  -- so_dong_khai_bao từ nay là sĩ số snapshot.
  INSERT INTO public.phieu_nhan_dien(
    ma_bang_diem,ma_thanh_phan,nguoi_tai,ma_bam_tep,
    duong_dan_anh_goc,so_dong_khai_bao
  ) VALUES (
    p_book,p_component,actor_id,p_checksum,p_object_key,roster_rows
  ) RETURNING ma_phieu INTO ticket_id;
  INSERT INTO public.danh_sach_phieu(ma_phieu,stt,ma_hoc_sinh,ho_ten)
  SELECT ticket_id,(e->>'stt')::integer,(e->>'studentId')::integer,e->>'fullName'
  FROM jsonb_array_elements(p_roster) e;
  result := jsonb_build_object(
    'ticketId',ticket_id::text,
    'jobId','recognition-'||ticket_id::text,
    'status','DANG_XU_LY',
    'storedObjectKey',p_object_key
  );
  INSERT INTO public.recognition_outbox(loai_su_kien,ma_phieu,du_lieu)
    VALUES('RECOGNITION_REQUESTED',ticket_id,result);
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_UPLOADED','phieu_nhan_dien:'||ticket_id::text);
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_UPLOAD',p_request_hash,result
  );
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION public.luu_ket_qua_nhan_dien(
  p_ticket bigint,
  p_model_version text,
  p_rows jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  ticket public.phieu_nhan_dien;
  item jsonb;
  row_index integer;
  row_stt integer;
  student_id integer;
  numeric_value numeric;
  written_value numeric;
  numeric_confidence numeric;
  written_confidence numeric;
  match_confidence numeric;
  stt_on_paper integer;
  name_read text;
  match_note text;
  name_crop text;
  row_total integer;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF length(p_model_version) NOT BETWEEN 1 AND 80
     OR jsonb_typeof(p_rows) <> 'array' THEN
    RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
  END IF;

  SELECT * INTO ticket FROM public.phieu_nhan_dien
  WHERE ma_phieu=p_ticket FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'TICKET_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  -- Phiếu đã hủy (kể cả hủy giữa lúc worker đang nhận dạng): bỏ qua kết quả, không ghi gì và không raise.
  IF ticket.trang_thai = 'DA_HUY' THEN RETURN; END IF;
  IF ticket.trang_thai IN ('CHO_DOI_CHIEU','DA_DUYET') THEN RETURN; END IF;
  IF ticket.trang_thai <> 'DANG_XU_LY' THEN
    RAISE EXCEPTION 'TICKET_NOT_PROCESSING' USING ERRCODE='23514';
  END IF;
  -- Số dòng có điểm ghép được từ 1 đến sĩ số snapshot (dòng gạch/trống bị bỏ, trang chỉ chứa một đoạn lớp).
  row_total := jsonb_array_length(p_rows);
  IF row_total NOT BETWEEN 1 AND ticket.so_dong_khai_bao THEN
    RAISE EXCEPTION 'GRID_ROW_COUNT_MISMATCH' USING ERRCODE='23514';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
    IF jsonb_typeof(item) <> 'object'
       OR NOT (item ?& ARRAY['order','stt','comparison','reviewLevel','numericCropKey','writtenCropKey','numeric','written'])
       OR jsonb_typeof(item->'order') <> 'number'
       OR jsonb_typeof(item->'stt') <> 'number'
       OR (item->>'order') !~ '^[1-9][0-9]{0,3}$'
       OR (item->>'stt') !~ '^[1-9][0-9]{0,8}$'
       OR jsonb_typeof(item->'comparison') <> 'string'
       OR jsonb_typeof(item->'reviewLevel') <> 'string'
       OR item->>'comparison' NOT IN ('KHOP','LECH','MOT_KENH','KHONG_DOC_DUOC')
       OR item->>'reviewLevel' NOT IN ('XANH','VANG','DO')
       OR jsonb_typeof(item->'numericCropKey') <> 'string'
       OR jsonb_typeof(item->'writtenCropKey') <> 'string'
       OR item->>'numericCropKey' !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-numeric[.]png$')
       OR item->>'writtenCropKey' !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-written[.]png$')
       OR jsonb_typeof(item->'numeric') <> 'object'
       OR jsonb_typeof(item->'written') <> 'object'
       -- Trường ghép tùy chọn: vắng hoặc null; nếu có thì phải đúng kiểu.
       OR (item ? 'sttOnPaper' AND jsonb_typeof(item->'sttOnPaper') NOT IN ('null','number'))
       OR (item ? 'nameRead' AND jsonb_typeof(item->'nameRead') NOT IN ('null','string'))
       OR (item ? 'matchConfidence' AND jsonb_typeof(item->'matchConfidence') NOT IN ('null','number'))
       OR (item ? 'matchNote' AND jsonb_typeof(item->'matchNote') NOT IN ('null','string'))
       OR (item ? 'nameCropKey' AND jsonb_typeof(item->'nameCropKey') NOT IN ('null','string'))
       -- Kênh gợi ý giá trị theo luật hợp nhất hai kênh: vắng/null (Đỏ) hoặc SO/CHU.
       OR (item ? 'suggestedSource' AND jsonb_typeof(item->'suggestedSource') NOT IN ('null','string'))
       OR (item->>'suggestedSource') NOT IN ('SO','CHU')
       -- Mức ghép học sinh (row-matching) tách riêng khỏi mức điểm: vắng/null (phiếu cũ) hoặc XANH/VANG/DO.
       OR (item ? 'matchLevel' AND jsonb_typeof(item->'matchLevel') NOT IN ('null','string'))
       OR (item->>'matchLevel') NOT IN ('XANH','VANG','DO') THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    row_index := (item->>'order')::integer;
    row_stt := (item->>'stt')::integer;
    stt_on_paper := CASE WHEN jsonb_typeof(item->'sttOnPaper')='number' THEN
      CASE WHEN (item->>'sttOnPaper') ~ '^[1-9][0-9]{0,8}$' THEN (item->>'sttOnPaper')::integer
           ELSE -1 END END;
    name_read := CASE WHEN jsonb_typeof(item->'nameRead')='string' THEN item->>'nameRead' END;
    match_note := CASE WHEN jsonb_typeof(item->'matchNote')='string' THEN item->>'matchNote' END;
    name_crop := CASE WHEN jsonb_typeof(item->'nameCropKey')='string' THEN item->>'nameCropKey' END;
    match_confidence := CASE WHEN jsonb_typeof(item->'matchConfidence')='number'
      THEN (item->>'matchConfidence')::numeric END;
    IF stt_on_paper = -1
       OR length(name_read) > 150
       OR length(match_note) > 200
       OR match_confidence NOT BETWEEN 0 AND 1
       OR (name_crop IS NOT NULL AND name_crop !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-name[.]png$'))
       OR EXISTS (SELECT 1 FROM public.ket_qua_dong
                  WHERE ma_phieu=p_ticket AND thu_tu_dong=row_index) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    -- Học sinh lấy từ danh sách lớp đã chốt khi tạo phiếu; STT ngoài snapshot hoặc dùng hai lần bị từ chối.
    SELECT ds.ma_hoc_sinh INTO student_id FROM public.danh_sach_phieu ds
    WHERE ds.ma_phieu=p_ticket AND ds.stt=row_stt;
    IF student_id IS NULL
       OR EXISTS (SELECT 1 FROM public.ket_qua_dong
                  WHERE ma_phieu=p_ticket AND ma_hoc_sinh=student_id) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    numeric_value := CASE WHEN item->'numeric'->>'value' IS NULL THEN NULL
      ELSE public.kiem_tra_gia_tri_diem((item->'numeric'->>'value')::numeric) END;
    written_value := CASE WHEN item->'written'->>'value' IS NULL THEN NULL
      ELSE public.kiem_tra_gia_tri_diem((item->'written'->>'value')::numeric) END;
    numeric_confidence := CASE WHEN item->'numeric'->>'confidence' IS NULL THEN NULL
      ELSE (item->'numeric'->>'confidence')::numeric END;
    written_confidence := CASE WHEN item->'written'->>'confidence' IS NULL THEN NULL
      ELSE (item->'written'->>'confidence')::numeric END;
    IF numeric_confidence NOT BETWEEN 0 AND 1 OR written_confidence NOT BETWEEN 0 AND 1
       OR ((item->'numeric'->>'isBlank')::boolean AND numeric_value IS NOT NULL)
       OR ((item->'written'->>'isBlank')::boolean AND written_value IS NOT NULL) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    INSERT INTO public.ket_qua_dong(
      ma_phieu,ma_hoc_sinh,thu_tu_dong,
      duong_dan_anh_o_so,duong_dan_anh_o_chu,
      raw_kenh_a,raw_kenh_b,gia_tri_kenh_a,gia_tri_kenh_b,
      do_tin_cay_a,do_tin_cay_b,ket_luan_doi_chieu,muc_phan_loai,
      stt_giay,ho_ten_doc_duoc,do_tin_cay_ghep,duong_dan_anh_o_ten,ghi_chu_ghep,kenh_goi_y,muc_ghep
    ) VALUES (
      p_ticket,student_id,row_index,
      item->>'numericCropKey',item->>'writtenCropKey',
      item->'numeric'->>'rawOutput',item->'written'->>'rawOutput',
      numeric_value,written_value,numeric_confidence,written_confidence,
      (item->>'comparison')::public."KetLuan",
      (item->>'reviewLevel')::public."MucPhanLoai",
      stt_on_paper,name_read,match_confidence,name_crop,match_note,
      item->>'suggestedSource',
      (item->>'matchLevel')::public."MucPhanLoai"
    );
  END LOOP;

  UPDATE public.phieu_nhan_dien SET
    so_dong_nhan_dien=row_total,
    phien_ban_mo_hinh=p_model_version,
    trang_thai='CHO_DOI_CHIEU',ma_loi=NULL,version=version+1
  WHERE ma_phieu=p_ticket;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(ticket.nguoi_tai,'RECOGNITION_COMPLETED','phieu_nhan_dien:'||p_ticket::text);
END $$;

CREATE FUNCTION public.huy_phieu_nhan_dien(
  p_phien text,
  p_book integer,
  p_ticket bigint,
  p_expected_version integer,
  p_reason text,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  ticket public.phieu_nhan_dien;
  prior public.khoa_idempotency;
  actor_id integer;
  assigned boolean;
  reason text;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  reason := btrim(p_reason);
  IF p_expected_version IS NULL OR p_expected_version < 0
     OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$'
     OR reason IS NULL OR length(reason) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION 'INVALID_CANCEL_REQUEST' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s
  JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  -- Khóa bảng điểm để tuần tự hóa với chốt cột (chốt cột kiểm phiếu đang chờ) và với duyệt phiếu.
  SELECT * INTO b FROM public.bang_diem
  WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  -- Giáo viên được phân công lớp–môn–học kỳ của bảng điểm, hoặc chính người đã tải phiếu lên.
  assigned := EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
      AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky);
  IF NOT assigned AND NOT EXISTS (SELECT 1 FROM public.phieu_nhan_dien
    WHERE ma_phieu=p_ticket AND ma_bang_diem=p_book AND nguoi_tai=actor_id) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_CANCEL'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  SELECT * INTO ticket FROM public.phieu_nhan_dien
  WHERE ma_phieu=p_ticket AND ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'TICKET_NOT_FOUND' USING ERRCODE='P0002'; END IF;

  -- Đã hủy: idempotent, trả lại đúng phiếu đã hủy (không đổi lý do, người, thời điểm hủy đầu tiên).
  IF ticket.trang_thai = 'DA_HUY' THEN
    RETURN jsonb_build_object(
      'ticketId',p_ticket::text,
      'ticketVersion',ticket.version,
      'gradebookId',p_book,
      'status','DA_HUY'
    );
  END IF;
  IF ticket.trang_thai = 'DA_DUYET' THEN
    RAISE EXCEPTION 'TICKET_ALREADY_APPROVED' USING ERRCODE='23514';
  END IF;
  IF ticket.version <> p_expected_version THEN
    RAISE EXCEPTION 'VERSION_CONFLICT' USING ERRCODE='23514';
  END IF;

  -- DANG_XU_LY / CHO_DOI_CHIEU / LOI: không động tới ket_qua_dong, danh_sach_phieu hay điểm chính thức.
  UPDATE public.phieu_nhan_dien SET
    trang_thai='DA_HUY',
    ly_do_huy=reason,
    nguoi_huy=actor_id,
    thoi_diem_huy=statement_timestamp(),
    version=version+1
  WHERE ma_phieu=p_ticket;
  -- Dispatcher không gửi lại sự kiện chưa gửi của phiếu đã hủy.
  UPDATE public.recognition_outbox SET
    da_gui_luc=statement_timestamp(),
    loi_cuoi='TICKET_CANCELLED'
  WHERE ma_phieu=p_ticket AND da_gui_luc IS NULL;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_CANCELLED','phieu_nhan_dien:'||p_ticket::text);

  result := jsonb_build_object(
    'ticketId',p_ticket::text,
    'ticketVersion',ticket.version+1,
    'gradebookId',p_book,
    'status','DA_HUY'
  );
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_CANCEL',p_request_hash,result
  );
  RETURN result;
END $$;

REVOKE ALL ON FUNCTION public.huy_phieu_nhan_dien(
  text,integer,bigint,integer,text,text,text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.huy_phieu_nhan_dien(
  text,integer,bigint,integer,text,text,text
) TO app_runtime;

COMMIT;
