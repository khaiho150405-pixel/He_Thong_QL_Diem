-- Lô nhận dạng nhiều trang, nhiều thành phần theo mẫu (ADR-0016 mục 3, phase P3).
--
--  - Enum "TrangThaiLo" (DANG_XU_LY|XONG|LOI|DA_HUY). Hai bảng kỹ thuật (ngoài 16 bảng nghiệp vụ): lo_nhan_dien (lô) và
--    trang_lo_nhan_dien (ảnh từng trang, 1..4, bất biến). Runtime chỉ SELECT; chỉ hàm SECURITY DEFINER bên dưới được ghi.
--    Không hard-delete lô hay trang (trigger chặn DELETE/TRUNCATE; trang còn chặn UPDATE).
--  - phieu_nhan_dien: thêm ma_lo, chi_so_cot_mau (ma_mau đã có từ 202610190001). Một lô tạo MỘT phiếu cho mỗi thành phần được
--    chọn; (ma_lo, ma_thanh_phan) và (ma_lo, chi_so_cot_mau) duy nhất. ma_bam_tep của phiếu thuộc lô là SHA-256 của
--    (checksum các trang theo thứ tự, ':' và mã thành phần) nên UNIQUE một phần hiện có vẫn phát hiện tải trùng.
--  - ket_qua_dong.so_trang (nullable; phiếu cũ là NULL). Trigger kiem_dong_theo_lo: dòng của phiếu thuộc lô bắt buộc có so_trang
--    và dòng của phiếu cũ bắt buộc không có, nên phiếu thuộc lô không ghi được qua luu_ket_qua_nhan_dien (đường cũ).
--  - recognition_outbox: ma_phieu nullable + ma_lo (UNIQUE) để MỘT sự kiện cho cả lô (RECOGNITION_BATCH_REQUESTED);
--    that_bai_outbox đánh dấu cả lô LOI khi hết số lần thử.
--  - Hàm: tao_lo_nhan_dien (tạo lô + trang + phiếu + danh sách lớp + audit + idempotency + outbox, SERIALIZABLE),
--    luu_ket_qua_lo (ghi kết quả mọi phiếu của lô trong một giao dịch), danh_dau_lo_nhan_dien_loi, huy_lo_nhan_dien.
--    Duyệt vẫn theo từng phiếu bằng duyet_phieu_nhan_dien (không đổi).
--
-- ROLLBACK (chỉ tiến khi đã có lô): lô, trang và kết quả dòng là bằng chứng nhận dạng nên không xóa. Nếu chưa có lô: DROP FUNCTION
-- tao_lo_nhan_dien, luu_ket_qua_lo, danh_dau_lo_nhan_dien_loi, huy_lo_nhan_dien; khôi phục that_bai_outbox (202609110001);
-- DROP TRIGGER ket_qua_dong_theo_lo + FUNCTION kiem_dong_theo_lo; DROP COLUMN ket_qua_dong.so_trang; khôi phục CHECK
-- recognition_outbox_payload cũ, DROP COLUMN recognition_outbox.ma_lo, SET NOT NULL recognition_outbox.ma_phieu; DROP COLUMN
-- phieu_nhan_dien.ma_lo, chi_so_cot_mau (kèm các constraint phieu_lo_*); DROP TABLE trang_lo_nhan_dien, lo_nhan_dien;
-- DROP TYPE "TrangThaiLo".
BEGIN;

CREATE TYPE public."TrangThaiLo" AS ENUM ('DANG_XU_LY', 'XONG', 'LOI', 'DA_HUY');

CREATE TABLE public.lo_nhan_dien (
  ma_lo bigserial PRIMARY KEY,
  ma_bang_diem integer NOT NULL REFERENCES public.bang_diem(ma_bang_diem) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ma_mau integer NOT NULL REFERENCES public.mau_bang_diem(ma_mau) ON DELETE RESTRICT ON UPDATE RESTRICT,
  nguoi_tai integer NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  so_trang integer NOT NULL,
  trang_thai public."TrangThaiLo" NOT NULL DEFAULT 'DANG_XU_LY',
  ma_loi varchar(80),
  -- Trang gây lỗi (1..so_trang); NULL khi lỗi không gắn với một trang (ghép học sinh, hạ tầng).
  trang_loi integer,
  phien_ban_mo_hinh varchar(80),
  version integer NOT NULL DEFAULT 0,
  ly_do_huy varchar(200),
  nguoi_huy integer REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  thoi_diem_huy timestamptz(6),
  ngay_tao timestamptz(6) NOT NULL DEFAULT now(),
  CONSTRAINT lo_so_trang_hop_le CHECK (so_trang BETWEEN 1 AND 4),
  CONSTRAINT lo_version_hop_le CHECK (version >= 0),
  CONSTRAINT lo_loi_hop_le CHECK (
    (trang_thai <> 'LOI' OR ma_loi IS NOT NULL)
    AND (ma_loi IS NULL OR trang_thai IN ('LOI', 'DA_HUY'))
    AND (trang_loi IS NULL OR (ma_loi IS NOT NULL AND trang_loi BETWEEN 1 AND so_trang))
  ),
  CONSTRAINT lo_huy_day_du CHECK (
    (trang_thai = 'DA_HUY') = (ly_do_huy IS NOT NULL AND nguoi_huy IS NOT NULL AND thoi_diem_huy IS NOT NULL)
  ),
  CONSTRAINT lo_huy_ly_do CHECK (ly_do_huy IS NULL OR length(btrim(ly_do_huy)) > 0)
);
CREATE INDEX lo_nhan_dien_bang_diem_idx ON public.lo_nhan_dien(ma_bang_diem, ma_lo);
CREATE INDEX lo_nhan_dien_ma_mau_idx ON public.lo_nhan_dien(ma_mau);
CREATE INDEX lo_nhan_dien_nguoi_tai_idx ON public.lo_nhan_dien(nguoi_tai);
CREATE INDEX lo_nhan_dien_nguoi_huy_idx ON public.lo_nhan_dien(nguoi_huy) WHERE nguoi_huy IS NOT NULL;

CREATE TABLE public.trang_lo_nhan_dien (
  ma_lo bigint NOT NULL REFERENCES public.lo_nhan_dien(ma_lo) ON DELETE RESTRICT ON UPDATE RESTRICT,
  so_trang integer NOT NULL,
  ma_bam_tep char(64) NOT NULL,
  duong_dan_anh varchar(512) NOT NULL,
  PRIMARY KEY (ma_lo, so_trang),
  CONSTRAINT trang_lo_so_trang_hop_le CHECK (so_trang BETWEEN 1 AND 4),
  CONSTRAINT trang_lo_ma_bam_hop_le CHECK (ma_bam_tep ~ '^[0-9a-f]{64}$'),
  CONSTRAINT trang_lo_duong_dan_hop_le CHECK (duong_dan_anh ~ '^recognition/original/[0-9a-f-]{36}[.](png|jpg)$'),
  -- Cùng một ảnh không được dùng cho hai trang của một lô.
  CONSTRAINT trang_lo_ma_bam_key UNIQUE (ma_lo, ma_bam_tep)
);

CREATE FUNCTION public.chan_xoa_lo_nhan_dien() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN RAISE EXCEPTION 'BATCH_DELETE_FORBIDDEN' USING ERRCODE='42501'; END;
$$;
CREATE TRIGGER lo_nhan_dien_khong_xoa BEFORE DELETE OR TRUNCATE ON public.lo_nhan_dien
  FOR EACH STATEMENT EXECUTE FUNCTION public.chan_xoa_lo_nhan_dien();
CREATE TRIGGER trang_lo_nhan_dien_bat_bien BEFORE UPDATE OR DELETE OR TRUNCATE ON public.trang_lo_nhan_dien
  FOR EACH STATEMENT EXECUTE FUNCTION public.chan_xoa_lo_nhan_dien();

REVOKE ALL ON TABLE public.lo_nhan_dien, public.trang_lo_nhan_dien FROM PUBLIC;
GRANT SELECT ON public.lo_nhan_dien, public.trang_lo_nhan_dien TO app_runtime;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.lo_nhan_dien, public.trang_lo_nhan_dien FROM app_runtime;

ALTER TABLE public.phieu_nhan_dien
  ADD COLUMN ma_lo bigint REFERENCES public.lo_nhan_dien(ma_lo) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ADD COLUMN chi_so_cot_mau integer,
  ADD CONSTRAINT phieu_lo_day_du CHECK (
    (ma_lo IS NULL) = (chi_so_cot_mau IS NULL) AND (ma_lo IS NULL OR ma_mau IS NOT NULL)
  ),
  ADD CONSTRAINT phieu_chi_so_cot_mau_hop_le CHECK (chi_so_cot_mau IS NULL OR chi_so_cot_mau BETWEEN 0 AND 63),
  -- Một lô có tối đa một phiếu cho mỗi thành phần và cho mỗi cột mẫu (NULL của phiếu cũ không tham gia).
  ADD CONSTRAINT phieu_lo_thanh_phan_key UNIQUE (ma_lo, ma_thanh_phan),
  ADD CONSTRAINT phieu_lo_cot_mau_key UNIQUE (ma_lo, chi_so_cot_mau);

ALTER TABLE public.ket_qua_dong
  ADD COLUMN so_trang integer,
  ADD CONSTRAINT dong_so_trang_hop_le CHECK (so_trang IS NULL OR so_trang BETWEEN 1 AND 4);

CREATE FUNCTION public.kiem_dong_theo_lo() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  batch_id bigint;
  pages integer;
BEGIN
  SELECT p.ma_lo INTO batch_id FROM public.phieu_nhan_dien p WHERE p.ma_phieu=NEW.ma_phieu;
  IF (batch_id IS NULL) <> (NEW.so_trang IS NULL) THEN
    RAISE EXCEPTION 'BATCH_ROW_PAGE_MISMATCH' USING ERRCODE='23514';
  END IF;
  IF batch_id IS NOT NULL THEN
    SELECT l.so_trang INTO pages FROM public.lo_nhan_dien l WHERE l.ma_lo=batch_id;
    IF NEW.so_trang > pages THEN
      RAISE EXCEPTION 'BATCH_ROW_PAGE_MISMATCH' USING ERRCODE='23514';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER ket_qua_dong_theo_lo BEFORE INSERT ON public.ket_qua_dong
  FOR EACH ROW EXECUTE FUNCTION public.kiem_dong_theo_lo();

ALTER TABLE public.recognition_outbox
  ALTER COLUMN ma_phieu DROP NOT NULL,
  ADD COLUMN ma_lo bigint UNIQUE REFERENCES public.lo_nhan_dien(ma_lo) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE public.recognition_outbox DROP CONSTRAINT recognition_outbox_payload;
ALTER TABLE public.recognition_outbox ADD CONSTRAINT recognition_outbox_payload CHECK (
  jsonb_typeof(du_lieu) = 'object'
  AND (
    (loai_su_kien = 'RECOGNITION_REQUESTED' AND ma_phieu IS NOT NULL AND ma_lo IS NULL
      AND du_lieu ?& ARRAY['ticketId','jobId'])
    OR (loai_su_kien = 'RECOGNITION_BATCH_REQUESTED' AND ma_lo IS NOT NULL AND ma_phieu IS NULL
      AND du_lieu ?& ARRAY['batchId','jobId','ticketId'])
  )
);

-- Hết số lần thử đẩy queue: phiếu (sự kiện cũ) hoặc cả lô và mọi phiếu đang xử lý của lô (sự kiện mới) chuyển LOI.
CREATE OR REPLACE FUNCTION public.that_bai_outbox(p_event bigint,p_error text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE failed_ticket bigint; failed_batch bigint; tries integer;
BEGIN
  UPDATE public.recognition_outbox
  SET khoa_den=NULL,
      san_sang_luc=statement_timestamp() + make_interval(secs => LEAST(60, power(2,so_lan_thu)::integer)),
      loi_cuoi=left(p_error,200),
      da_gui_luc=CASE WHEN so_lan_thu >= 5 THEN statement_timestamp() ELSE NULL END
  WHERE ma_su_kien=p_event AND da_gui_luc IS NULL
  RETURNING ma_phieu,ma_lo,so_lan_thu INTO failed_ticket,failed_batch,tries;
  IF failed_ticket IS NOT NULL AND tries >= 5 THEN
    UPDATE public.phieu_nhan_dien
    SET trang_thai='LOI',ma_loi='QUEUE_UNAVAILABLE',version=version+1
    WHERE ma_phieu=failed_ticket AND trang_thai='DANG_XU_LY';
  END IF;
  IF failed_batch IS NOT NULL AND tries >= 5 THEN
    UPDATE public.phieu_nhan_dien
    SET trang_thai='LOI',ma_loi='QUEUE_UNAVAILABLE',version=version+1
    WHERE ma_lo=failed_batch AND trang_thai='DANG_XU_LY';
    UPDATE public.lo_nhan_dien
    SET trang_thai='LOI',ma_loi='QUEUE_UNAVAILABLE',version=version+1
    WHERE ma_lo=failed_batch AND trang_thai='DANG_XU_LY';
  END IF;
END $$;

-- Tạo lô. p_components: [{templateColumnIndex, componentId}] (1..20); p_pages: [{page, checksum, objectKey}] (1..4, page = 1..n
-- theo thứ tự); p_roster: danh sách lớp đã chốt như tao_phieu_nhan_dien. Trả {batchId, jobId, status, storedObjectKeys, tickets}.
-- Lỗi (mã nằm trong thông điệp): TOO_MANY_PAGES, TEMPLATE_NOT_FOUND (P0002), TEMPLATE_INACTIVE, COMPONENT_NOT_MAPPABLE,
-- COLUMN_LOCKED, GRADE_ENTRY_WINDOW_CLOSED, RECOGNITION_ALREADY_PENDING, DUPLICATE_FILE (23505), INVALID_ROSTER_SNAPSHOT, ...
CREATE FUNCTION public.tao_lo_nhan_dien(
  p_phien text,
  p_book integer,
  p_template integer,
  p_components jsonb,
  p_pages jsonb,
  p_roster jsonb,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  tpl public.mau_bang_diem;
  col public.cot_mau;
  comp public.thanh_phan_diem;
  prior public.khoa_idempotency;
  item jsonb;
  actor_id integer;
  page_count integer;
  component_count integer;
  active_rows integer;
  roster_rows integer;
  batch_id bigint;
  ticket_id bigint;
  first_ticket bigint;
  ticket_hash text;
  page_hashes text;
  first_key text;
  tickets jsonb := '[]'::jsonb;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_request_hash !~ '^[0-9a-f]{64}$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$'
     OR p_pages IS NULL OR jsonb_typeof(p_pages) <> 'array'
     OR p_components IS NULL OR jsonb_typeof(p_components) <> 'array' THEN
    RAISE EXCEPTION 'INVALID_RECOGNITION_REQUEST' USING ERRCODE='23514';
  END IF;
  page_count := jsonb_array_length(p_pages);
  IF page_count > 4 THEN
    RAISE EXCEPTION 'TOO_MANY_PAGES' USING ERRCODE='23514';
  END IF;
  component_count := jsonb_array_length(p_components);
  IF page_count < 1 OR component_count NOT BETWEEN 1 AND 20 THEN
    RAISE EXCEPTION 'INVALID_RECOGNITION_REQUEST' USING ERRCODE='23514';
  END IF;
  -- Hình dạng từng trang: đúng ba khóa, page = vị trí 1..n, checksum SHA-256, khóa object do API sinh.
  IF EXISTS (
       SELECT 1 FROM jsonb_array_elements(p_pages) e
       WHERE jsonb_typeof(e) <> 'object'
         OR (SELECT count(*) FROM jsonb_object_keys(e)) <> 3
         OR NOT (e ?& ARRAY['page','checksum','objectKey'])
         OR jsonb_typeof(e->'page') <> 'number'
         OR jsonb_typeof(e->'checksum') <> 'string'
         OR jsonb_typeof(e->'objectKey') <> 'string'
         OR (e->>'page') !~ '^[1-4]$'
         OR (e->>'checksum') !~ '^[0-9a-f]{64}$'
         OR (e->>'objectKey') !~ '^recognition/original/[0-9a-f-]{36}[.](png|jpg)$'
     )
     OR (SELECT count(DISTINCT (e->>'page')::integer) FROM jsonb_array_elements(p_pages) e) <> page_count
     OR (SELECT max((e->>'page')::integer) FROM jsonb_array_elements(p_pages) e) <> page_count
     OR (SELECT count(DISTINCT e->>'objectKey') FROM jsonb_array_elements(p_pages) e) <> page_count THEN
    RAISE EXCEPTION 'INVALID_RECOGNITION_REQUEST' USING ERRCODE='23514';
  END IF;
  IF (SELECT count(DISTINCT e->>'checksum') FROM jsonb_array_elements(p_pages) e) <> page_count THEN
    RAISE EXCEPTION 'DUPLICATE_FILE' USING ERRCODE='23505';
  END IF;
  -- Hình dạng ánh xạ: đúng hai khóa nguyên dương, không trùng cột mẫu hay thành phần.
  IF EXISTS (
       SELECT 1 FROM jsonb_array_elements(p_components) e
       WHERE jsonb_typeof(e) <> 'object'
         OR (SELECT count(*) FROM jsonb_object_keys(e)) <> 2
         OR NOT (e ?& ARRAY['templateColumnIndex','componentId'])
         OR jsonb_typeof(e->'templateColumnIndex') <> 'number'
         OR jsonb_typeof(e->'componentId') <> 'number'
         OR (e->>'templateColumnIndex') !~ '^[0-9]{1,2}$'
         OR (e->>'componentId') !~ '^[1-9][0-9]{0,8}$'
     )
     OR (SELECT count(DISTINCT (e->>'templateColumnIndex')::integer) FROM jsonb_array_elements(p_components) e) <> component_count
     OR (SELECT count(DISTINCT (e->>'componentId')::integer) FROM jsonb_array_elements(p_components) e) <> component_count THEN
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

  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
       WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
         AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_BATCH_UPLOAD'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  IF b.trang_thai <> 'DANG_NHAP_LIEU' THEN
    RAISE EXCEPTION 'GRADEBOOK_NOT_EDITABLE' USING ERRCODE='23514';
  END IF;
  IF EXISTS (SELECT 1 FROM public.mon_hoc WHERE ma_mon=b.ma_mon AND danh_gia_dat) THEN
    RAISE EXCEPTION 'PASS_FAIL_SUBJECT_NOT_RECOGNIZABLE' USING ERRCODE='23514';
  END IF;

  SELECT * INTO tpl FROM public.mau_bang_diem WHERE ma_mau=p_template;
  IF NOT FOUND THEN RAISE EXCEPTION 'TEMPLATE_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF tpl.trang_thai <> 'DANG_DUNG' THEN
    RAISE EXCEPTION 'TEMPLATE_INACTIVE' USING ERRCODE='23514';
  END IF;

  -- Hình dạng snapshot: mảng 1..2000 object đúng ba khóa {stt, studentId, fullName} (như tao_phieu_nhan_dien).
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

  SELECT string_agg(e->>'checksum', ',' ORDER BY (e->>'page')::integer) INTO page_hashes
  FROM jsonb_array_elements(p_pages) e;
  SELECT e->>'objectKey' INTO first_key FROM jsonb_array_elements(p_pages) e WHERE (e->>'page')::integer=1;

  INSERT INTO public.lo_nhan_dien(ma_bang_diem,ma_mau,nguoi_tai,so_trang)
  VALUES (p_book,p_template,actor_id,page_count) RETURNING ma_lo INTO batch_id;
  INSERT INTO public.trang_lo_nhan_dien(ma_lo,so_trang,ma_bam_tep,duong_dan_anh)
  SELECT batch_id,(e->>'page')::integer,e->>'checksum',e->>'objectKey'
  FROM jsonb_array_elements(p_pages) e;

  FOR item IN
    SELECT value FROM jsonb_array_elements(p_components)
    ORDER BY (value->>'templateColumnIndex')::integer
  LOOP
    SELECT * INTO col FROM public.cot_mau
    WHERE ma_mau=p_template AND chi_so_cot=(item->>'templateColumnIndex')::integer AND vai_tro='DIEM';
    IF NOT FOUND THEN
      RAISE EXCEPTION 'COMPONENT_NOT_MAPPABLE' USING ERRCODE='23514';
    END IF;
    SELECT * INTO comp FROM public.thanh_phan_diem
    WHERE ma_thanh_phan=(item->>'componentId')::integer AND ma_mon=b.ma_mon;
    -- Khớp ánh xạ gợi ý: cùng nhóm hệ số và đứng đúng thứ tự trong nhóm theo (thu_tu_hien_thi, ma_thanh_phan) của môn.
    IF NOT FOUND
       OR comp.loai_he_so <> col.loai_he_so
       OR (SELECT count(*) FROM public.thanh_phan_diem t
           WHERE t.ma_mon=b.ma_mon AND t.loai_he_so=col.loai_he_so
             AND (t.thu_tu_hien_thi,t.ma_thanh_phan) <= (comp.thu_tu_hien_thi,comp.ma_thanh_phan))
          <> col.thu_tu_trong_nhom THEN
      RAISE EXCEPTION 'COMPONENT_NOT_MAPPABLE' USING ERRCODE='23514';
    END IF;
    IF EXISTS (SELECT 1 FROM public.chot_cot_diem
               WHERE ma_bang_diem=p_book AND ma_thanh_phan=comp.ma_thanh_phan) THEN
      RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514';
    END IF;
    PERFORM public.kiem_thoi_gian_nhap(p_book,comp.ma_thanh_phan);

    ticket_hash := encode(sha256(convert_to(page_hashes||':'||comp.ma_thanh_phan::text,'UTF8')),'hex');
    IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien
      WHERE ma_bam_tep=ticket_hash AND trang_thai <> 'DA_HUY') THEN
      RAISE EXCEPTION 'DUPLICATE_FILE' USING ERRCODE='23505';
    END IF;
    IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien
      WHERE ma_bang_diem=p_book AND ma_thanh_phan=comp.ma_thanh_phan
        AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
      RAISE EXCEPTION 'RECOGNITION_ALREADY_PENDING' USING ERRCODE='23514';
    END IF;

    INSERT INTO public.phieu_nhan_dien(
      ma_bang_diem,ma_thanh_phan,nguoi_tai,ma_bam_tep,
      duong_dan_anh_goc,so_dong_khai_bao,ma_mau,ma_lo,chi_so_cot_mau
    ) VALUES (
      p_book,comp.ma_thanh_phan,actor_id,ticket_hash,
      first_key,roster_rows,p_template,batch_id,col.chi_so_cot
    ) RETURNING ma_phieu INTO ticket_id;
    IF first_ticket IS NULL THEN first_ticket := ticket_id; END IF;
    INSERT INTO public.danh_sach_phieu(ma_phieu,stt,ma_hoc_sinh,ho_ten)
    SELECT ticket_id,(e->>'stt')::integer,(e->>'studentId')::integer,e->>'fullName'
    FROM jsonb_array_elements(p_roster) e;
    INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
      VALUES(actor_id,'RECOGNITION_UPLOADED','phieu_nhan_dien:'||ticket_id::text);
    tickets := tickets || jsonb_build_array(jsonb_build_object(
      'ticketId',ticket_id::text,
      'componentId',comp.ma_thanh_phan,
      'templateColumnIndex',col.chi_so_cot
    ));
  END LOOP;

  result := jsonb_build_object(
    'batchId',batch_id::text,
    'jobId','recognition-batch-'||batch_id::text,
    'status','DANG_XU_LY',
    'storedObjectKeys',(SELECT jsonb_agg(e->>'objectKey' ORDER BY (e->>'page')::integer)
                        FROM jsonb_array_elements(p_pages) e),
    'tickets',tickets
  );
  -- MỘT sự kiện cho cả lô; ticketId là phiếu đại diện (cột mẫu đứng đầu), chỉ để ghi log.
  INSERT INTO public.recognition_outbox(loai_su_kien,ma_lo,du_lieu)
    VALUES('RECOGNITION_BATCH_REQUESTED',batch_id,
      jsonb_build_object('batchId',batch_id::text,'jobId','recognition-batch-'||batch_id::text,
        'ticketId',first_ticket::text));
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_BATCH_UPLOADED','lo_nhan_dien:'||batch_id::text);
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_BATCH_UPLOAD',p_request_hash,result
  );
  RETURN result;
END $$;

-- Ghi kết quả của MỌI phiếu trong lô trong một giao dịch. p_tickets: [{ticketId, rows:[...]}]; mỗi dòng như
-- luu_ket_qua_nhan_dien cộng `page` (1..so_trang) và `order` = (page-1)*1000 + vị trí dòng trên trang (duy nhất trong phiếu).
-- Lô đã hủy (kể cả hủy giữa lúc worker chạy) hoặc đã XONG: bỏ qua, không ghi gì. Phiếu đã hủy riêng lẻ: bỏ qua phiếu đó.
-- Phiếu cột một kênh (không có cột DIEM_CHU đi kèm): không được Xanh, không có kênh chữ, không gợi ý từ kênh chữ.
-- Dòng mức cuối Đỏ không lưu gợi ý (bất biến 4).
CREATE FUNCTION public.luu_ket_qua_lo(
  p_batch bigint,
  p_model_version text,
  p_tickets jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  lot public.lo_nhan_dien;
  ticket public.phieu_nhan_dien;
  entry jsonb;
  item jsonb;
  entry_id bigint;
  single_channel boolean;
  row_page integer;
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
  written_crop text;
  suggestion text;
  row_total integer;
  seen_tickets bigint[] := '{}';
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF length(p_model_version) NOT BETWEEN 1 AND 80
     OR p_tickets IS NULL OR jsonb_typeof(p_tickets) <> 'array' THEN
    RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
  END IF;

  SELECT * INTO lot FROM public.lo_nhan_dien WHERE ma_lo=p_batch FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'BATCH_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  -- Lô đã hủy (kể cả hủy giữa lúc worker đang nhận dạng) hoặc đã có kết quả: bỏ qua, không ghi gì và không raise.
  IF lot.trang_thai IN ('DA_HUY','XONG') THEN RETURN; END IF;
  IF lot.trang_thai <> 'DANG_XU_LY' THEN
    RAISE EXCEPTION 'BATCH_NOT_PROCESSING' USING ERRCODE='23514';
  END IF;

  -- Khóa mọi phiếu của lô theo thứ tự cố định.
  PERFORM 1 FROM public.phieu_nhan_dien WHERE ma_lo=p_batch ORDER BY ma_phieu FOR UPDATE;

  FOR entry IN SELECT value FROM jsonb_array_elements(p_tickets) LOOP
    IF jsonb_typeof(entry) <> 'object'
       OR (SELECT count(*) FROM jsonb_object_keys(entry)) <> 2
       OR NOT (entry ?& ARRAY['ticketId','rows'])
       OR jsonb_typeof(entry->'ticketId') <> 'string'
       OR (entry->>'ticketId') !~ '^[1-9][0-9]{0,18}$'
       OR jsonb_typeof(entry->'rows') <> 'array' THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;
    entry_id := (entry->>'ticketId')::bigint;
    IF entry_id = ANY(seen_tickets) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;
    seen_tickets := array_append(seen_tickets, entry_id);
    SELECT * INTO ticket FROM public.phieu_nhan_dien WHERE ma_phieu=entry_id AND ma_lo=p_batch;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;
    -- Phiếu đã hủy riêng lẻ: bỏ kết quả của phiếu đó.
    IF ticket.trang_thai = 'DA_HUY' THEN CONTINUE; END IF;
    IF ticket.trang_thai <> 'DANG_XU_LY' THEN
      RAISE EXCEPTION 'TICKET_NOT_PROCESSING' USING ERRCODE='23514';
    END IF;

    -- Cột mẫu một kênh: không có cột DIEM_CHU trỏ tới cột điểm của phiếu.
    single_channel := NOT EXISTS (
      SELECT 1 FROM public.cot_mau d
      WHERE d.ma_mau=ticket.ma_mau AND d.vai_tro='DIEM_CHU' AND d.cot_diem_di_kem=ticket.chi_so_cot_mau);

    row_total := jsonb_array_length(entry->'rows');
    IF row_total NOT BETWEEN 1 AND ticket.so_dong_khai_bao THEN
      RAISE EXCEPTION 'GRID_ROW_COUNT_MISMATCH' USING ERRCODE='23514';
    END IF;

    FOR item IN SELECT value FROM jsonb_array_elements(entry->'rows') LOOP
      IF jsonb_typeof(item) <> 'object'
         OR NOT (item ?& ARRAY['page','order','stt','comparison','reviewLevel','numericCropKey','numeric','written'])
         OR jsonb_typeof(item->'page') <> 'number'
         OR jsonb_typeof(item->'order') <> 'number'
         OR jsonb_typeof(item->'stt') <> 'number'
         OR (item->>'page') !~ '^[1-4]$'
         OR (item->>'order') !~ '^[1-9][0-9]{0,3}$'
         OR (item->>'stt') !~ '^[1-9][0-9]{0,8}$'
         OR jsonb_typeof(item->'comparison') <> 'string'
         OR jsonb_typeof(item->'reviewLevel') <> 'string'
         OR item->>'comparison' NOT IN ('KHOP','LECH','MOT_KENH','KHONG_DOC_DUOC')
         OR item->>'reviewLevel' NOT IN ('XANH','VANG','DO')
         OR jsonb_typeof(item->'numericCropKey') <> 'string'
         OR item->>'numericCropKey' !~ ('^recognition/crops/'||ticket.ma_phieu::text||'/[0-9]+-numeric[.]png$')
         OR jsonb_typeof(item->'numeric') <> 'object'
         OR jsonb_typeof(item->'written') <> 'object'
         -- Ảnh ô chữ: chuỗi với cột hai kênh; vắng hoặc null với cột một kênh.
         OR (item ? 'writtenCropKey' AND jsonb_typeof(item->'writtenCropKey') NOT IN ('null','string'))
         OR (item ? 'sttOnPaper' AND jsonb_typeof(item->'sttOnPaper') NOT IN ('null','number'))
         OR (item ? 'nameRead' AND jsonb_typeof(item->'nameRead') NOT IN ('null','string'))
         OR (item ? 'matchConfidence' AND jsonb_typeof(item->'matchConfidence') NOT IN ('null','number'))
         OR (item ? 'matchNote' AND jsonb_typeof(item->'matchNote') NOT IN ('null','string'))
         OR (item ? 'nameCropKey' AND jsonb_typeof(item->'nameCropKey') NOT IN ('null','string'))
         OR (item ? 'suggestedSource' AND jsonb_typeof(item->'suggestedSource') NOT IN ('null','string'))
         OR (item->>'suggestedSource') NOT IN ('SO','CHU')
         OR (item ? 'matchLevel' AND jsonb_typeof(item->'matchLevel') NOT IN ('null','string'))
         OR (item->>'matchLevel') NOT IN ('XANH','VANG','DO') THEN
        RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
      END IF;

      row_page := (item->>'page')::integer;
      row_index := (item->>'order')::integer;
      row_stt := (item->>'stt')::integer;
      stt_on_paper := CASE WHEN jsonb_typeof(item->'sttOnPaper')='number' THEN
        CASE WHEN (item->>'sttOnPaper') ~ '^[1-9][0-9]{0,8}$' THEN (item->>'sttOnPaper')::integer
             ELSE -1 END END;
      name_read := CASE WHEN jsonb_typeof(item->'nameRead')='string' THEN item->>'nameRead' END;
      match_note := CASE WHEN jsonb_typeof(item->'matchNote')='string' THEN item->>'matchNote' END;
      name_crop := CASE WHEN jsonb_typeof(item->'nameCropKey')='string' THEN item->>'nameCropKey' END;
      written_crop := CASE WHEN jsonb_typeof(item->'writtenCropKey')='string' THEN item->>'writtenCropKey' END;
      suggestion := CASE WHEN jsonb_typeof(item->'suggestedSource')='string' THEN item->>'suggestedSource' END;
      match_confidence := CASE WHEN jsonb_typeof(item->'matchConfidence')='number'
        THEN (item->>'matchConfidence')::numeric END;
      -- order = (page-1)*1000 + vị trí dòng: phải nằm trong khoảng của trang và trang không vượt số trang của lô.
      IF row_page > lot.so_trang
         OR row_index NOT BETWEEN (row_page-1)*1000+1 AND row_page*1000
         OR stt_on_paper = -1
         OR length(name_read) > 150
         OR length(match_note) > 200
         OR match_confidence NOT BETWEEN 0 AND 1
         OR (name_crop IS NOT NULL AND name_crop !~ ('^recognition/crops/'||ticket.ma_phieu::text||'/[0-9]+-name[.]png$'))
         OR (single_channel AND written_crop IS NOT NULL)
         OR (NOT single_channel AND (written_crop IS NULL
             OR written_crop !~ ('^recognition/crops/'||ticket.ma_phieu::text||'/[0-9]+-written[.]png$')))
         -- Cột một kênh không bao giờ Xanh, không khớp/lệch hai kênh và không gợi ý từ kênh chữ (D-01).
         OR (single_channel AND (item->>'reviewLevel' = 'XANH' OR item->>'comparison' IN ('KHOP','LECH')
             OR suggestion = 'CHU'))
         -- Đỏ không gợi ý giá trị (bất biến 4): KHONG_DOC_DUOC luôn Đỏ; Đỏ ở mức điểm không có kênh gợi ý.
         OR (item->>'comparison' = 'KHONG_DOC_DUOC' AND (item->>'reviewLevel' <> 'DO' OR suggestion IS NOT NULL))
         OR (item->>'reviewLevel' = 'XANH' AND item->>'comparison' <> 'KHOP')
         OR EXISTS (SELECT 1 FROM public.ket_qua_dong
                    WHERE ma_phieu=ticket.ma_phieu AND thu_tu_dong=row_index) THEN
        RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
      END IF;

      -- Học sinh lấy từ danh sách lớp đã chốt của phiếu; STT ngoài snapshot hoặc dùng hai lần (kể cả ở hai trang) bị từ chối.
      SELECT ds.ma_hoc_sinh INTO student_id FROM public.danh_sach_phieu ds
      WHERE ds.ma_phieu=ticket.ma_phieu AND ds.stt=row_stt;
      IF student_id IS NULL
         OR EXISTS (SELECT 1 FROM public.ket_qua_dong
                    WHERE ma_phieu=ticket.ma_phieu AND ma_hoc_sinh=student_id) THEN
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
         OR ((item->'written'->>'isBlank')::boolean AND written_value IS NOT NULL)
         OR (single_channel AND (written_value IS NOT NULL OR written_confidence IS NOT NULL)) THEN
        RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
      END IF;

      INSERT INTO public.ket_qua_dong(
        ma_phieu,ma_hoc_sinh,thu_tu_dong,so_trang,
        duong_dan_anh_o_so,duong_dan_anh_o_chu,
        raw_kenh_a,raw_kenh_b,gia_tri_kenh_a,gia_tri_kenh_b,
        do_tin_cay_a,do_tin_cay_b,ket_luan_doi_chieu,muc_phan_loai,
        stt_giay,ho_ten_doc_duoc,do_tin_cay_ghep,duong_dan_anh_o_ten,ghi_chu_ghep,kenh_goi_y,muc_ghep
      ) VALUES (
        ticket.ma_phieu,student_id,row_index,row_page,
        item->>'numericCropKey',written_crop,
        item->'numeric'->>'rawOutput',item->'written'->>'rawOutput',
        numeric_value,written_value,numeric_confidence,written_confidence,
        (item->>'comparison')::public."KetLuan",
        (item->>'reviewLevel')::public."MucPhanLoai",
        stt_on_paper,name_read,match_confidence,name_crop,match_note,
        CASE WHEN item->>'reviewLevel' = 'DO' THEN NULL ELSE suggestion END,
        (item->>'matchLevel')::public."MucPhanLoai"
      );
    END LOOP;

    UPDATE public.phieu_nhan_dien SET
      so_dong_nhan_dien=row_total,
      phien_ban_mo_hinh=p_model_version,
      trang_thai='CHO_DOI_CHIEU',ma_loi=NULL,version=version+1
    WHERE ma_phieu=ticket.ma_phieu;
    INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
      VALUES(ticket.nguoi_tai,'RECOGNITION_COMPLETED','phieu_nhan_dien:'||ticket.ma_phieu::text);
  END LOOP;

  -- Mọi phiếu chưa hủy của lô đều phải có kết quả: thiếu một phiếu thì không ghi nửa chừng.
  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien
             WHERE ma_lo=p_batch AND trang_thai='DANG_XU_LY') THEN
    RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
  END IF;

  UPDATE public.lo_nhan_dien SET
    trang_thai='XONG',ma_loi=NULL,trang_loi=NULL,phien_ban_mo_hinh=p_model_version,version=version+1
  WHERE ma_lo=p_batch;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(lot.nguoi_tai,'RECOGNITION_BATCH_COMPLETED','lo_nhan_dien:'||p_batch::text);
END $$;

-- Một trang lỗi (hoặc không ghép được học sinh) -> cả lô LOI và mọi phiếu đang xử lý của lô LOI cùng mã; không ghi dòng nào.
CREATE FUNCTION public.danh_dau_lo_nhan_dien_loi(
  p_batch bigint,
  p_code text,
  p_page integer
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; pages integer;
BEGIN
  IF p_code !~ '^[A-Z0-9_]{1,80}$' OR (p_page IS NOT NULL AND p_page NOT BETWEEN 1 AND 4) THEN
    RAISE EXCEPTION 'INVALID_ERROR_CODE' USING ERRCODE='23514';
  END IF;
  SELECT so_trang INTO pages FROM public.lo_nhan_dien WHERE ma_lo=p_batch FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'BATCH_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF p_page IS NOT NULL AND p_page > pages THEN
    RAISE EXCEPTION 'INVALID_ERROR_CODE' USING ERRCODE='23514';
  END IF;
  UPDATE public.lo_nhan_dien SET trang_thai='LOI',ma_loi=p_code,trang_loi=p_page,version=version+1
  WHERE ma_lo=p_batch AND trang_thai='DANG_XU_LY'
  RETURNING nguoi_tai INTO actor_id;
  IF actor_id IS NOT NULL THEN
    UPDATE public.phieu_nhan_dien SET trang_thai='LOI',ma_loi=p_code,version=version+1
    WHERE ma_lo=p_batch AND trang_thai='DANG_XU_LY';
    INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
      VALUES(actor_id,'RECOGNITION_BATCH_FAILED',left('lo_nhan_dien:'||p_batch::text||':'||p_code,100));
  END IF;
END $$;

-- Hủy mềm lô: mọi phiếu chưa duyệt của lô -> DA_HUY; phiếu đã duyệt giữ nguyên (bằng chứng, điểm đã ghi). Theo khuôn mẫu
-- huy_phieu_nhan_dien (phiên, quyền, idempotency, audit). Trả {batchId, batchVersion, gradebookId, status, cancelledTickets}.
CREATE FUNCTION public.huy_lo_nhan_dien(
  p_phien text,
  p_book integer,
  p_batch bigint,
  p_reason text,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  lot public.lo_nhan_dien;
  t public.phieu_nhan_dien;
  prior public.khoa_idempotency;
  actor_id integer;
  assigned boolean;
  reason text;
  cancelled integer := 0;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  reason := btrim(p_reason);
  IF p_request_hash !~ '^[0-9a-f]{64}$'
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

  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  -- Chỉ giáo viên đang được phân công lớp–môn–học kỳ của bảng điểm (AGENTS 7.9); người tải lô mà đã mất phân công thì không hủy.
  assigned := EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
      AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky);
  IF NOT assigned THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_BATCH_CANCEL'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  -- Lô phải thuộc đúng bảng điểm trên đường dẫn (chống IDOR theo batchId của bảng điểm khác).
  SELECT * INTO lot FROM public.lo_nhan_dien
  WHERE ma_lo=p_batch AND ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'BATCH_NOT_FOUND' USING ERRCODE='P0002'; END IF;

  -- Đã hủy: idempotent, trả lại đúng lô đã hủy (không đổi lý do, người, thời điểm hủy đầu tiên).
  IF lot.trang_thai = 'DA_HUY' THEN
    RETURN jsonb_build_object(
      'batchId',p_batch::text,'batchVersion',lot.version,'gradebookId',p_book,
      'status','DA_HUY','cancelledTickets',0);
  END IF;

  FOR t IN SELECT * FROM public.phieu_nhan_dien WHERE ma_lo=p_batch ORDER BY ma_phieu FOR UPDATE LOOP
    IF t.trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU','LOI') THEN
      UPDATE public.phieu_nhan_dien SET
        trang_thai='DA_HUY',
        ly_do_huy=reason,
        nguoi_huy=actor_id,
        thoi_diem_huy=statement_timestamp(),
        version=version+1
      WHERE ma_phieu=t.ma_phieu;
      INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
        VALUES(actor_id,'RECOGNITION_CANCELLED','phieu_nhan_dien:'||t.ma_phieu::text);
      cancelled := cancelled + 1;
    END IF;
  END LOOP;
  -- Mọi phiếu của lô đã duyệt: không còn gì để hủy.
  IF cancelled = 0 AND EXISTS (SELECT 1 FROM public.phieu_nhan_dien
                               WHERE ma_lo=p_batch AND trang_thai='DA_DUYET') THEN
    RAISE EXCEPTION 'TICKET_ALREADY_APPROVED' USING ERRCODE='23514';
  END IF;

  UPDATE public.lo_nhan_dien SET
    trang_thai='DA_HUY',
    ly_do_huy=reason,
    nguoi_huy=actor_id,
    thoi_diem_huy=statement_timestamp(),
    version=version+1
  WHERE ma_lo=p_batch;
  -- Dispatcher không gửi lại sự kiện chưa gửi của lô đã hủy.
  UPDATE public.recognition_outbox SET
    da_gui_luc=statement_timestamp(),
    loi_cuoi='BATCH_CANCELLED'
  WHERE ma_lo=p_batch AND da_gui_luc IS NULL;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_BATCH_CANCELLED','lo_nhan_dien:'||p_batch::text);

  result := jsonb_build_object(
    'batchId',p_batch::text,'batchVersion',lot.version+1,'gradebookId',p_book,
    'status','DA_HUY','cancelledTickets',cancelled);
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_BATCH_CANCEL',p_request_hash,result
  );
  RETURN result;
END $$;

REVOKE ALL ON FUNCTION public.kiem_dong_theo_lo() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.chan_xoa_lo_nhan_dien() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.tao_lo_nhan_dien(
  text,integer,integer,jsonb,jsonb,jsonb,text,text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.luu_ket_qua_lo(bigint,text,jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.danh_dau_lo_nhan_dien_loi(bigint,text,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.huy_lo_nhan_dien(text,integer,bigint,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tao_lo_nhan_dien(
  text,integer,integer,jsonb,jsonb,jsonb,text,text
) TO app_runtime;
GRANT EXECUTE ON FUNCTION public.luu_ket_qua_lo(bigint,text,jsonb) TO app_runtime;
GRANT EXECUTE ON FUNCTION public.danh_dau_lo_nhan_dien_loi(bigint,text,integer) TO app_runtime;
GRANT EXECUTE ON FUNCTION public.huy_lo_nhan_dien(text,integer,bigint,text,text,text) TO app_runtime;

COMMIT;
