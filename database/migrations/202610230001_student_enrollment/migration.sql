-- Ghi danh học sinh theo lớp/năm học (ADR-0018, đợt A).
-- hoc_sinh_lop là nguồn sự thật về lớp của học sinh theo thời gian; hoc_sinh.ma_lop và hoc_sinh.dang_theo_hoc (DEPRECATED) chỉ
-- còn là "lớp hiện tại", do trigger giữ đồng bộ. Mọi nơi cần "học sinh của lớp trong một học kỳ" dùng hoc_sinh_cua_lop().
--
-- ROLLBACK (chỉ tiến): không xóa hoc_sinh_lop khi đã có ghi danh ngoài dữ liệu chuyển đổi. Muốn gỡ, tạo migration mới khôi phục
-- các hàm cũ (xem phiên bản liền trước của từng hàm trong chú thích bên dưới), bỏ trigger rồi bảng.
BEGIN;

CREATE TYPE public."TrangThaiGhiDanh" AS ENUM ('DANG_HOC','LEN_LOP','LUU_BAN','DA_CHUYEN_LOP','NGHI_HOC','TOT_NGHIEP');

CREATE TABLE public.hoc_sinh_lop (
  ma bigserial PRIMARY KEY,
  ma_hoc_sinh integer NOT NULL REFERENCES public.hoc_sinh(ma_hoc_sinh) ON DELETE RESTRICT,
  ma_lop integer NOT NULL REFERENCES public.lop(ma_lop) ON DELETE RESTRICT,
  ma_nam_hoc integer NOT NULL REFERENCES public.nam_hoc(ma_nam_hoc) ON DELETE RESTRICT,
  tu_ngay date NOT NULL,
  den_ngay date,
  trang_thai public."TrangThaiGhiDanh" NOT NULL DEFAULT 'DANG_HOC',
  ly_do varchar(500),
  nguoi_thuc_hien integer REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT,
  tao_luc timestamptz(6) NOT NULL DEFAULT now(),
  CONSTRAINT hoc_sinh_lop_duy_nhat UNIQUE (ma_hoc_sinh, ma_lop),
  CONSTRAINT hoc_sinh_lop_dang_hoc_chua_dong CHECK ((trang_thai = 'DANG_HOC') = (den_ngay IS NULL)),
  CONSTRAINT hoc_sinh_lop_khoang CHECK (den_ngay IS NULL OR den_ngay >= tu_ngay)
);
-- Tối đa một ghi danh DANG_HOC cho mỗi học sinh trong một năm học.
CREATE UNIQUE INDEX hoc_sinh_lop_mot_dang_hoc ON public.hoc_sinh_lop(ma_hoc_sinh, ma_nam_hoc) WHERE trang_thai = 'DANG_HOC';
CREATE INDEX hoc_sinh_lop_lop_idx ON public.hoc_sinh_lop(ma_lop);
CREATE INDEX hoc_sinh_lop_nam_idx ON public.hoc_sinh_lop(ma_nam_hoc);
GRANT SELECT ON public.hoc_sinh_lop TO app_runtime;

-- ma_nam_hoc luôn là năm học của lớp.
CREATE FUNCTION public.kiem_ghi_danh_nam() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
DECLARE y integer;
BEGIN
  SELECT ma_nam_hoc INTO y FROM public.lop WHERE ma_lop=NEW.ma_lop;
  IF y IS NULL OR (NEW.ma_nam_hoc IS NOT NULL AND NEW.ma_nam_hoc<>y) THEN
    RAISE EXCEPTION 'ENROLLMENT_YEAR_MISMATCH' USING ERRCODE='23514'; END IF;
  NEW.ma_nam_hoc:=y;
  RETURN NEW;
END $$;
CREATE TRIGGER enrollment_year_guard BEFORE INSERT OR UPDATE ON public.hoc_sinh_lop
  FOR EACH ROW EXECUTE FUNCTION public.kiem_ghi_danh_nam();

CREATE FUNCTION public.khong_xoa_ghi_danh() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN RAISE EXCEPTION 'ENROLLMENT_APPEND_ONLY' USING ERRCODE='23514'; END $$;
CREATE TRIGGER enrollment_no_delete BEFORE DELETE ON public.hoc_sinh_lop
  FOR EACH ROW EXECUTE FUNCTION public.khong_xoa_ghi_danh();
CREATE TRIGGER enrollment_no_truncate BEFORE TRUNCATE ON public.hoc_sinh_lop
  FOR EACH STATEMENT EXECUTE FUNCTION public.khong_xoa_ghi_danh();

-- Chuyển dữ liệu: mỗi học sinh hiện có → đúng một ghi danh theo lớp hiện tại (trước khi bật các trigger đồng bộ).
INSERT INTO public.hoc_sinh_lop(ma_hoc_sinh,ma_lop,ma_nam_hoc,tu_ngay,den_ngay,trang_thai,ly_do)
SELECT hs.ma_hoc_sinh,hs.ma_lop,n.ma_nam_hoc,n.ngay_bat_dau,
  CASE WHEN hs.dang_theo_hoc THEN NULL ELSE greatest(CURRENT_DATE,n.ngay_bat_dau) END,
  CASE WHEN hs.dang_theo_hoc THEN 'DANG_HOC' ELSE 'NGHI_HOC' END::public."TrangThaiGhiDanh",
  CASE WHEN hs.dang_theo_hoc THEN NULL ELSE 'Chuyển đổi dữ liệu' END
FROM public.hoc_sinh hs JOIN public.lop l ON l.ma_lop=hs.ma_lop JOIN public.nam_hoc n ON n.ma_nam_hoc=l.ma_nam_hoc;

-- Đồng bộ "lớp hiện tại" trên hoc_sinh theo ghi danh: DANG_HOC có tu_ngay mới nhất; không có thì giữ ma_lop của ghi danh gần nhất
-- và dang_theo_hoc=false. Chỉ trigger này (lồng trong trigger khác) được sửa hai cột đó; xem kiem_sua_lop_hoc_sinh.
CREATE FUNCTION public.dong_bo_lop_hien_tai() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE cur integer; found_active boolean:=false;
BEGIN
  SELECT g.ma_lop INTO cur FROM public.hoc_sinh_lop g
  WHERE g.ma_hoc_sinh=NEW.ma_hoc_sinh AND g.trang_thai='DANG_HOC' ORDER BY g.tu_ngay DESC,g.ma DESC LIMIT 1;
  IF FOUND THEN found_active:=true;
  ELSE
    SELECT g.ma_lop INTO cur FROM public.hoc_sinh_lop g WHERE g.ma_hoc_sinh=NEW.ma_hoc_sinh
    ORDER BY coalesce(g.den_ngay,'infinity'::date) DESC,g.tu_ngay DESC,g.ma DESC LIMIT 1;
  END IF;
  UPDATE public.hoc_sinh SET ma_lop=cur,dang_theo_hoc=found_active
  WHERE ma_hoc_sinh=NEW.ma_hoc_sinh AND (ma_lop IS DISTINCT FROM cur OR dang_theo_hoc IS DISTINCT FROM found_active);
  RETURN NULL;
END $$;
CREATE TRIGGER enrollment_sync_current AFTER INSERT OR UPDATE ON public.hoc_sinh_lop
  FOR EACH ROW EXECUTE FUNCTION public.dong_bo_lop_hien_tai();

-- Sửa trực tiếp ma_lop/dang_theo_hoc ngoài trigger đồng bộ → STUDENT_CLASS_VIA_ENROLLMENT (trigger lồng nhau có độ sâu > 1).
CREATE FUNCTION public.kiem_sua_lop_hoc_sinh() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF (NEW.ma_lop IS DISTINCT FROM OLD.ma_lop OR NEW.dang_theo_hoc IS DISTINCT FROM OLD.dang_theo_hoc)
     AND pg_trigger_depth()<2 THEN
    RAISE EXCEPTION 'STUDENT_CLASS_VIA_ENROLLMENT' USING ERRCODE='23514'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER student_class_guard BEFORE UPDATE ON public.hoc_sinh
  FOR EACH ROW EXECUTE FUNCTION public.kiem_sua_lop_hoc_sinh();

-- Tương thích ngược: INSERT hoc_sinh có ma_lop mà chưa có ghi danh → tạo ghi danh đầu tiên.
CREATE FUNCTION public.tao_ghi_danh_dau_tien() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE start_date date; y integer;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=NEW.ma_hoc_sinh) THEN
    SELECT n.ngay_bat_dau,n.ma_nam_hoc INTO start_date,y FROM public.lop l JOIN public.nam_hoc n ON n.ma_nam_hoc=l.ma_nam_hoc
    WHERE l.ma_lop=NEW.ma_lop;
    INSERT INTO public.hoc_sinh_lop(ma_hoc_sinh,ma_lop,ma_nam_hoc,tu_ngay,den_ngay,trang_thai,ly_do)
    VALUES(NEW.ma_hoc_sinh,NEW.ma_lop,y,start_date,
      CASE WHEN NEW.dang_theo_hoc THEN NULL ELSE greatest(CURRENT_DATE,start_date) END,
      CASE WHEN NEW.dang_theo_hoc THEN 'DANG_HOC' ELSE 'NGHI_HOC' END::public."TrangThaiGhiDanh",
      CASE WHEN NEW.dang_theo_hoc THEN NULL ELSE 'Tạo hồ sơ' END);
  END IF;
  RETURN NULL;
END $$;
CREATE TRIGGER student_first_enrollment AFTER INSERT ON public.hoc_sinh
  FOR EACH ROW EXECUTE FUNCTION public.tao_ghi_danh_dau_tien();

-- HÀM DÙNG CHUNG: học sinh của một lớp trong một học kỳ (ghi danh chồng lấn học kỳ). con_hoc = còn tính vào bảng điểm/tổng kết.
CREATE FUNCTION public.hoc_sinh_cua_lop(p_lop integer,p_hoc_ky integer)
RETURNS TABLE(ma_hoc_sinh integer, ho_ten text, con_hoc boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT hs.ma_hoc_sinh, hs.ho_ten::text,
    (g.trang_thai IN ('DANG_HOC','LEN_LOP','LUU_BAN','TOT_NGHIEP') OR g.den_ngay >= k.ngay_ket_thuc)
  FROM public.hoc_sinh_lop g
  JOIN public.hoc_ky k ON k.ma_hoc_ky=p_hoc_ky
  JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh=g.ma_hoc_sinh
  WHERE g.ma_lop=p_lop AND g.tu_ngay <= k.ngay_ket_thuc AND (g.den_ngay IS NULL OR g.den_ngay >= k.ngay_bat_dau)
$$;
REVOKE ALL ON FUNCTION public.hoc_sinh_cua_lop(integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.hoc_sinh_cua_lop(integer,integer) TO app_runtime;

-- cap_nhat_diem: thân giữ nguyên từ 202610220002_adjustment_hardening, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.cap_nhat_diem(p_phien text, p_book integer, p_version integer, p_changes jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; d public.diem_thanh_phan; c jsonb; v numeric;
 actor_id integer; items jsonb:='[]'::jsonb; seen bigint[]:='{}'; cell_id bigint; reason text;
BEGIN
 b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
 SELECT ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec WHERE ma_bam=p_phien;
 IF p_changes IS NULL OR jsonb_typeof(p_changes)<>'array' THEN
   RAISE EXCEPTION 'INVALID_CHANGES' USING ERRCODE='23514'; END IF;
 IF jsonb_array_length(p_changes) NOT BETWEEN 1 AND 100 THEN
   RAISE EXCEPTION 'INVALID_BATCH_SIZE' USING ERRCODE='23514'; END IF;
 FOR c IN SELECT value FROM jsonb_array_elements(p_changes) LOOP
   IF jsonb_typeof(c)<>'object' OR NOT (c ?& ARRAY['cellId','value','reason'])
   OR (c-ARRAY['cellId','value','reason'])<>'{}'::jsonb
   OR jsonb_typeof(c->'cellId')<>'string' OR (c->>'cellId')!~'^[1-9][0-9]{0,18}$'
   OR jsonb_typeof(c->'reason')<>'string' THEN
     RAISE EXCEPTION 'INVALID_CHANGE' USING ERRCODE='23514'; END IF;
   cell_id:=(c->>'cellId')::bigint;
   IF cell_id=ANY(seen) THEN RAISE EXCEPTION 'DUPLICATE_CELL' USING ERRCODE='23514'; END IF;
   seen:=array_append(seen,cell_id);
   reason:=btrim(c->>'reason');
   IF length(reason) NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'INVALID_REASON' USING ERRCODE='23514'; END IF;
   IF c->'value'='null'::jsonb THEN v:=NULL;
   ELSE
     IF jsonb_typeof(c->'value')<>'string' OR (c->>'value')!~'^(10[.]0|[0-9][.][0-9])$' THEN
       RAISE EXCEPTION 'INVALID_GRADE' USING ERRCODE='23514'; END IF;
     v:=public.kiem_tra_gia_tri_diem((c->>'value')::numeric);
   END IF;
   SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id AND ma_bang_diem=p_book;
   IF NOT FOUND THEN RAISE EXCEPTION 'CELL_OUTSIDE_BOOK' USING ERRCODE='P0002'; END IF;
   IF d.trang_thai='MIEN' THEN RAISE EXCEPTION 'CELL_EXEMPT' USING ERRCODE='23514'; END IF;
   PERFORM public.kiem_thoi_gian_nhap(p_book,d.ma_thanh_phan);
   -- Cột đã chốt chỉ sửa được qua phiếu điều chỉnh (duyet_phieu_dieu_chinh), không phụ thuộc trigger kiem_cot_diem.
   IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan) THEN
     RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
   IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) s WHERE s.ma_hoc_sinh=d.ma_hoc_sinh AND s.con_hoc)
   OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon)
   -- Kiểm tra cột điểm có đang được Admin cho phép nhập không
   OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon AND cho_phep_nhap)
   OR d.trang_thai='CHO_DOI_CHIEU' OR EXISTS(SELECT 1 FROM public.phieu_nhan_dien
     WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
     RAISE EXCEPTION 'CELL_NOT_EDITABLE' USING ERRCODE='23514'; END IF;
   IF d.gia_tri IS DISTINCT FROM v THEN
     UPDATE public.diem_thanh_phan SET gia_tri=v,
       trang_thai=CASE WHEN v IS NULL THEN 'CHUA_CO'::public."TrangThaiDiem" ELSE 'DA_DUYET'::public."TrangThaiDiem" END,
       nguon_nhap='NHAP_TAY' WHERE ma_diem=cell_id;
     INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
       VALUES(cell_id,actor_id,d.gia_tri,v,reason);
   END IF;
   SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id;
   items:=items || jsonb_build_array(jsonb_build_object('id',d.ma_diem::text,
     'value',d.gia_tri::text,'status',d.trang_thai,'source',d.nguon_nhap));
 END LOOP;
 UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADES_UPDATED','bang_diem:'||p_book);
 RETURN jsonb_build_object('items',items,'bookId',p_book,'version',b.version+1);
END $$;

-- dat_mien_diem: thân giữ nguyên từ 202610210003_cell_exempt, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.dat_mien_diem(p_phien text,p_book integer,p_version integer,p_changes jsonb,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; d public.diem_thanh_phan; c jsonb; w record; prior public.khoa_idempotency;
  actor_id integer; seen bigint[]:='{}'; cell_id bigint; reason text; wants boolean; ids jsonb:='[]'::jsonb; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  IF p_version IS NULL OR p_version<0 OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$'
     OR p_changes IS NULL OR jsonb_typeof(p_changes)<>'array' OR jsonb_array_length(p_changes) NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'INVALID_EXEMPTION_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.phan_cong_giang_day pc WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
    AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='GRADE_EXEMPT' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF b.trang_thai='DA_CHOT' OR b.version<>p_version THEN
    RAISE EXCEPTION 'EXEMPTION_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514'; END IF;
  b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
  FOR c IN SELECT value FROM jsonb_array_elements(p_changes) LOOP
    IF jsonb_typeof(c)<>'object' OR NOT (c ?& ARRAY['cellId','exempt','reason'])
       OR (c-ARRAY['cellId','exempt','reason'])<>'{}'::jsonb
       OR jsonb_typeof(c->'cellId')<>'string' OR (c->>'cellId')!~'^[1-9][0-9]{0,18}$'
       OR (c->>'cellId')::numeric>9223372036854775807
       OR jsonb_typeof(c->'exempt')<>'boolean' OR jsonb_typeof(c->'reason')<>'string' THEN
      RAISE EXCEPTION 'INVALID_EXEMPTION_CHANGE' USING ERRCODE='23514'; END IF;
    cell_id:=(c->>'cellId')::bigint;
    IF cell_id=ANY(seen) THEN RAISE EXCEPTION 'DUPLICATE_CELL' USING ERRCODE='23514'; END IF;
    seen:=array_append(seen,cell_id);
    reason:=btrim(c->>'reason');
    IF length(reason) NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'INVALID_REASON' USING ERRCODE='23514'; END IF;
    wants:=(c->>'exempt')::boolean;
    SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id AND ma_bang_diem=p_book FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'CELL_OUTSIDE_BOOK' USING ERRCODE='P0002'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) s WHERE s.ma_hoc_sinh=d.ma_hoc_sinh AND s.con_hoc)
       OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon) THEN
      RAISE EXCEPTION 'CELL_NOT_EDITABLE' USING ERRCODE='23514'; END IF;
    SELECT * INTO w FROM public.lich_hieu_luc(p_book,d.ma_thanh_phan);
    IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan)
       OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND cho_phep_nhap)
       OR (w.dong_luc IS NOT NULL AND (clock_timestamp()<w.mo_luc OR clock_timestamp()>=w.dong_luc)) THEN
      RAISE EXCEPTION 'COLUMN_NOT_OPEN' USING ERRCODE='23514'; END IF;
    IF EXISTS(SELECT 1 FROM public.phieu_nhan_dien WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan
       AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
      RAISE EXCEPTION 'RECOGNITION_PENDING' USING ERRCODE='23514'; END IF;
    IF wants THEN
      IF d.trang_thai<>'MIEN' THEN
        IF d.gia_tri IS NOT NULL OR d.trang_thai<>'CHUA_CO' THEN
          RAISE EXCEPTION 'CELL_HAS_VALUE' USING ERRCODE='23514'; END IF;
        UPDATE public.diem_thanh_phan SET trang_thai='MIEN' WHERE ma_diem=cell_id;
        INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(cell_id,'MIEN',reason,actor_id);
      END IF;
    ELSE
      IF d.trang_thai<>'MIEN' THEN RAISE EXCEPTION 'CELL_NOT_EXEMPT' USING ERRCODE='23514'; END IF;
      UPDATE public.diem_thanh_phan SET trang_thai='CHUA_CO' WHERE ma_diem=cell_id;
      INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(cell_id,'BO_MIEN',reason,actor_id);
    END IF;
    ids:=ids||to_jsonb(cell_id::text);
  END LOOP;
  UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADE_CELLS_EXEMPTION_CHANGED','bang_diem:'||p_book);
  result:=jsonb_build_object('bookId',p_book,'version',b.version+1,'cellIds',ids);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'GRADE_EXEMPT',p_hash,result);
  RETURN result;
END $$;

-- gui_phieu_dieu_chinh: thân giữ nguyên từ 202610220001_adjustments, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.gui_phieu_dieu_chinh(
  p_phien text,p_book integer,p_version integer,p_reason text,p_changes jsonb,p_idem text,p_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; d public.diem_thanh_phan; c jsonb; prior public.khoa_idempotency; actor_id integer;
  reason text; note text; adj_id bigint; cell_id bigint; seen bigint[]:='{}'; exempt boolean; v numeric; lines integer:=0;
  pass_fail boolean; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  reason:=btrim(coalesce(p_reason,''));
  IF p_version IS NULL OR p_version<0 OR length(reason) NOT BETWEEN 1 AND 500
     OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$'
     OR p_changes IS NULL OR jsonb_typeof(p_changes)<>'array' OR jsonb_array_length(p_changes) NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'INVALID_ADJUSTMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.phan_cong_giang_day pc WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
    AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ADJUST_SUBMIT' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
    RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
  IF b.version<>p_version THEN RAISE EXCEPTION 'ADJUSTMENT_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514'; END IF;
  IF EXISTS(SELECT 1 FROM public.phieu_dieu_chinh WHERE ma_bang_diem=p_book AND trang_thai='CHO_DUYET') THEN
    RAISE EXCEPTION 'ADJUSTMENT_PENDING_EXISTS' USING ERRCODE='23514'; END IF;
  SELECT danh_gia_dat INTO pass_fail FROM public.mon_hoc WHERE ma_mon=b.ma_mon;
  INSERT INTO public.phieu_dieu_chinh(ma_bang_diem,nguoi_gui,ly_do,phien_ban_bang_khi_gui)
  VALUES(p_book,actor_id,reason,b.version) RETURNING ma INTO adj_id;
  FOR c IN SELECT value FROM jsonb_array_elements(p_changes) LOOP
    IF jsonb_typeof(c)<>'object' OR NOT (c ?& ARRAY['cellId','value','exempt'])
       OR (c-ARRAY['cellId','value','exempt','note'])<>'{}'::jsonb
       OR jsonb_typeof(c->'cellId')<>'string' OR (c->>'cellId')!~'^[1-9][0-9]{0,18}$'
       OR (c->>'cellId')::numeric>9223372036854775807
       OR jsonb_typeof(c->'exempt')<>'boolean'
       OR jsonb_typeof(c->'value') NOT IN ('string','null')
       OR jsonb_typeof(coalesce(c->'note','null'::jsonb)) NOT IN ('string','null') THEN
      RAISE EXCEPTION 'INVALID_ADJUSTMENT_CHANGE' USING ERRCODE='23514'; END IF;
    cell_id:=(c->>'cellId')::bigint;
    IF cell_id=ANY(seen) THEN RAISE EXCEPTION 'DUPLICATE_CELL' USING ERRCODE='23514'; END IF;
    seen:=array_append(seen,cell_id);
    exempt:=(c->>'exempt')::boolean;
    note:=nullif(btrim(coalesce(c->>'note','')),'');
    IF length(coalesce(note,''))>200 THEN RAISE EXCEPTION 'INVALID_ADJUSTMENT_CHANGE' USING ERRCODE='23514'; END IF;
    IF exempt THEN
      IF jsonb_typeof(c->'value')<>'null' THEN RAISE EXCEPTION 'INVALID_ADJUSTMENT_CHANGE' USING ERRCODE='23514'; END IF;
      v:=NULL;
    ELSE
      IF jsonb_typeof(c->'value')<>'string' OR (c->>'value')!~'^(10[.]0|[0-9][.][0-9])$' THEN
        RAISE EXCEPTION 'INVALID_GRADE' USING ERRCODE='23514'; END IF;
      v:=public.kiem_tra_gia_tri_diem((c->>'value')::numeric);
      IF pass_fail AND v NOT IN (0.0,10.0) THEN RAISE EXCEPTION 'PASS_FAIL_VALUE_REQUIRED' USING ERRCODE='23514'; END IF;
    END IF;
    SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id AND ma_bang_diem=p_book;
    IF NOT FOUND THEN RAISE EXCEPTION 'CELL_OUTSIDE_BOOK' USING ERRCODE='P0002'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) s WHERE s.ma_hoc_sinh=d.ma_hoc_sinh AND s.con_hoc)
       OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon) THEN
      RAISE EXCEPTION 'CELL_NOT_EDITABLE' USING ERRCODE='23514'; END IF;
    IF NOT EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan) THEN
      RAISE EXCEPTION 'CELL_NOT_LOCKED' USING ERRCODE='23514'; END IF;
    -- Dòng không đổi gì so với hiện tại thì bỏ.
    IF exempt AND d.trang_thai='MIEN' THEN CONTINUE; END IF;
    IF NOT exempt AND d.trang_thai='DA_DUYET' AND d.gia_tri=v THEN CONTINUE; END IF;
    INSERT INTO public.dong_dieu_chinh(ma_phieu,ma_diem,gia_tri_cu,trang_thai_cu,gia_tri_moi,mien_moi,ghi_chu)
    VALUES(adj_id,cell_id,d.gia_tri,d.trang_thai,v,exempt,note);
    lines:=lines+1;
  END LOOP;
  IF lines=0 THEN RAISE EXCEPTION 'ADJUSTMENT_NO_CHANGE' USING ERRCODE='23514'; END IF;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ADJUSTMENT_SUBMITTED','phieu_dieu_chinh:'||adj_id);
  result:=jsonb_build_object('id',adj_id::text);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ADJUST_SUBMIT',p_hash,result);
  RETURN result;
END $$;

-- dong_bo_si_so: thân giữ nguyên từ 202609100003_gradebook_write, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.dong_bo_si_so(p_phien text,p_book integer,p_version integer)
RETURNS SETOF public.bang_diem LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; actor_id integer;
BEGIN
 b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
 SELECT ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec WHERE ma_bam=p_phien;
 INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan)
 SELECT p_book,hs.ma_hoc_sinh,tp.ma_thanh_phan FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs CROSS JOIN public.thanh_phan_diem tp
 WHERE hs.con_hoc AND tp.ma_mon=b.ma_mon
 ON CONFLICT(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) DO NOTHING;
 UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADEBOOK_ROSTER_SYNCED','bang_diem:'||p_book);
 RETURN QUERY SELECT * FROM public.bang_diem WHERE ma_bang_diem=p_book;
END $$;

-- duyet_phieu_nhan_dien: thân giữ nguyên từ 202610210003_cell_exempt, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.duyet_phieu_nhan_dien(
  p_phien text,
  p_book integer,
  p_ticket bigint,
  p_ticket_version integer,
  p_book_version integer,
  p_decisions jsonb,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  ticket public.phieu_nhan_dien;
  evidence public.ket_qua_dong;
  grade public.diem_thanh_phan;
  prior public.khoa_idempotency;
  item jsonb;
  actor_id integer;
  row_id bigint;
  final_value numeric;
  reason text;
  seen bigint[] := '{}';
  reviewed integer := 0;
  machine_matched integer := 0;
  error_rows integer := 0;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_ticket_version < 0 OR p_book_version < 0
     OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$'
     OR jsonb_typeof(p_decisions) <> 'array'
     OR jsonb_array_length(p_decisions) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'INVALID_REVIEW_REQUEST' USING ERRCODE='23514';
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
  IF NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
      AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_APPROVE'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  IF b.trang_thai <> 'DANG_NHAP_LIEU' OR b.version <> p_book_version THEN
    RAISE EXCEPTION 'GRADEBOOK_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  SELECT * INTO ticket FROM public.phieu_nhan_dien
  WHERE ma_phieu=p_ticket AND ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'TICKET_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  PERFORM public.kiem_thoi_gian_nhap(p_book,ticket.ma_thanh_phan);
  IF ticket.trang_thai <> 'CHO_DOI_CHIEU'
     OR ticket.version <> p_ticket_version THEN
    RAISE EXCEPTION 'TICKET_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  IF jsonb_array_length(p_decisions) <>
     (SELECT count(*) FROM public.ket_qua_dong WHERE ma_phieu=p_ticket) THEN
    RAISE EXCEPTION 'ALL_ROWS_REQUIRED' USING ERRCODE='23514';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_decisions) LOOP
    IF jsonb_typeof(item) <> 'object'
       OR NOT (item ?& ARRAY['rowId','value','reason'])
       OR (item-ARRAY['rowId','value','reason']) <> '{}'::jsonb
       OR jsonb_typeof(item->'rowId') <> 'string'
       OR (item->>'rowId') !~ '^[1-9][0-9]{0,18}$'
       OR (item->>'rowId')::numeric > 9223372036854775807
       OR jsonb_typeof(item->'reason') <> 'string' THEN
      RAISE EXCEPTION 'INVALID_REVIEW_DECISION' USING ERRCODE='23514';
    END IF;
    row_id := (item->>'rowId')::bigint;
    IF row_id=ANY(seen) THEN
      RAISE EXCEPTION 'DUPLICATE_REVIEW_ROW' USING ERRCODE='23514';
    END IF;
    seen := array_append(seen,row_id);
    reason := btrim(item->>'reason');
    IF length(reason) NOT BETWEEN 1 AND 500 THEN
      RAISE EXCEPTION 'INVALID_REVIEW_REASON' USING ERRCODE='23514';
    END IF;
    IF item->'value'='null'::jsonb THEN
      final_value := NULL;
    ELSE
      IF jsonb_typeof(item->'value') <> 'string'
         OR (item->>'value') !~ '^(10[.]0|[0-9][.][0-9])$' THEN
        RAISE EXCEPTION 'INVALID_REVIEW_GRADE' USING ERRCODE='23514';
      END IF;
      final_value := public.kiem_tra_gia_tri_diem((item->>'value')::numeric);
    END IF;

    SELECT * INTO evidence FROM public.ket_qua_dong
    WHERE ma_dong=row_id AND ma_phieu=p_ticket FOR UPDATE;
    IF NOT FOUND OR evidence.nguoi_duyet IS NOT NULL OR evidence.ma_diem IS NOT NULL THEN
      RAISE EXCEPTION 'REVIEW_ROW_NOT_AVAILABLE' USING ERRCODE='P0002';
    END IF;
    IF final_value IS NULL THEN
      -- Không ghi điểm cho dòng này (ví dụ học sinh vắng): không động tới diem_thanh_phan của học sinh đó,
      -- chỉ lưu người duyệt, thời điểm và lý do bắt buộc trên chính dòng kết quả.
      UPDATE public.ket_qua_dong SET
        nguoi_duyet=actor_id,
        thoi_diem_duyet=statement_timestamp(),
        ly_do_duyet=reason
      WHERE ma_dong=row_id;
    ELSE
      SELECT d.* INTO grade FROM public.diem_thanh_phan d
      JOIN public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs ON hs.ma_hoc_sinh=d.ma_hoc_sinh
      WHERE d.ma_bang_diem=p_book
        AND d.ma_hoc_sinh=evidence.ma_hoc_sinh
        AND d.ma_thanh_phan=ticket.ma_thanh_phan
        AND hs.con_hoc
      FOR UPDATE OF d;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'GRADE_CELL_NOT_FOUND' USING ERRCODE='P0002';
      END IF;
      IF grade.trang_thai='MIEN' THEN
        RAISE EXCEPTION 'ROW_STUDENT_EXEMPT' USING ERRCODE='23514';
      END IF;

      IF grade.gia_tri IS DISTINCT FROM final_value THEN
        INSERT INTO public.lich_su_sua_diem(
          ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do
        ) VALUES (grade.ma_diem,actor_id,grade.gia_tri,final_value,reason);
      END IF;
      UPDATE public.diem_thanh_phan SET
        gia_tri=final_value,
        trang_thai='DA_DUYET'::public."TrangThaiDiem",
        nguon_nhap='NHAN_DIEN'
      WHERE ma_diem=grade.ma_diem;
      UPDATE public.ket_qua_dong SET
        ma_diem=grade.ma_diem,
        gia_tri_chot=final_value,
        nguoi_duyet=actor_id,
        thoi_diem_duyet=statement_timestamp(),
        ly_do_duyet=reason
      WHERE ma_dong=row_id;
    END IF;

    reviewed := reviewed+1;
    IF evidence.muc_phan_loai='XANH'
       AND final_value IS NOT NULL
       AND final_value IS NOT DISTINCT FROM evidence.gia_tri_kenh_a
       AND final_value IS NOT DISTINCT FROM evidence.gia_tri_kenh_b THEN
      machine_matched := machine_matched+1;
    END IF;
    IF evidence.muc_phan_loai='DO' THEN error_rows := error_rows+1; END IF;
  END LOOP;

  UPDATE public.phieu_nhan_dien SET
    trang_thai='DA_DUYET',version=version+1
  WHERE ma_phieu=p_ticket;
  UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_APPROVED','phieu_nhan_dien:'||p_ticket::text);
  result := jsonb_build_object(
    'ticketId',p_ticket::text,
    'ticketVersion',ticket.version+1,
    'gradebookId',p_book,
    'gradebookVersion',b.version+1,
    'reviewedRows',reviewed,
    'machineMatchedRows',machine_matched,
    'humanCorrectedRows',reviewed-machine_matched,
    'errorRows',error_rows,
    'status','DA_DUYET'
  );
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_APPROVE',p_request_hash,result
  );
  RETURN result;
END $$;

-- hoc_sinh_thieu_o: thân giữ nguyên từ 202610210003_cell_exempt, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.hoc_sinh_thieu_o(p_book integer) RETURNS TABLE(ma_hoc_sinh integer, ho_ten text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT hs.ma_hoc_sinh, hs.ho_ten::text
  FROM public.bang_diem b CROSS JOIN LATERAL public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs
  WHERE b.ma_bang_diem=p_book AND hs.con_hoc
    AND EXISTS(SELECT 1 FROM public.thanh_phan_diem tp WHERE tp.ma_mon=b.ma_mon
      AND NOT EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=b.ma_bang_diem
        AND d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.ma_thanh_phan=tp.ma_thanh_phan))
  ORDER BY hs.ma_hoc_sinh
$$;

-- khoi_tao_bang_diem_hoc_ky: thân giữ nguyên từ 202610210001_semester_deadlines, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.khoi_tao_bang_diem_hoc_ky(p_phien text,p_term integer,p_idem text,p_hash text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; t public.hoc_ky; prior public.khoa_idempotency; a record; bk public.bang_diem;
 created jsonb:='[]'::jsonb; skipped jsonb:='[]'::jsonb; result jsonb;
BEGIN
 IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
 IF p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$' OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
 RAISE EXCEPTION 'INVALID_INITIALIZE_REQUEST' USING ERRCODE='23514'; END IF;
 SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
 WHERE s.ma_bam=p_phien AND u.vai_tro='QUAN_TRI_VIEN' AND u.trang_thai AND s.het_han>statement_timestamp() AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
 IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT * INTO t FROM public.hoc_ky WHERE ma_hoc_ky=p_term FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
 SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='GRADEBOOK_INITIALIZE' AND khoa=p_idem;
 IF FOUND THEN
 IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
 RETURN prior.ket_qua;
 END IF;
 IF t.da_cong_bo THEN RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
 FOR a IN SELECT pc.ma_lop,pc.ma_mon,l.ten_lop,m.ten_mon FROM public.phan_cong_giang_day pc
 JOIN public.lop l ON l.ma_lop=pc.ma_lop JOIN public.mon_hoc m ON m.ma_mon=pc.ma_mon
 WHERE pc.ma_hoc_ky=p_term AND l.ma_nam_hoc=t.ma_nam_hoc
 AND NOT EXISTS(SELECT 1 FROM public.bang_diem b WHERE b.ma_lop=pc.ma_lop AND b.ma_mon=pc.ma_mon AND b.ma_hoc_ky=p_term)
 ORDER BY l.ten_lop,m.ten_mon,pc.ma_lop,pc.ma_mon LOOP
 IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh_cua_lop(a.ma_lop,p_term) s WHERE s.con_hoc) THEN
 skipped:=skipped||jsonb_build_array(jsonb_build_object('classId',a.ma_lop,'className',a.ten_lop,'subjectId',a.ma_mon,'subjectName',a.ten_mon,'reason','EMPTY_ROSTER'));
 ELSIF NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon=a.ma_mon) THEN
 skipped:=skipped||jsonb_build_array(jsonb_build_object('classId',a.ma_lop,'className',a.ten_lop,'subjectId',a.ma_mon,'subjectName',a.ten_mon,'reason','NO_COMPONENTS'));
 ELSE
 bk:=public.tao_luoi_diem_noi_bo(actor_id,a.ma_lop,a.ma_mon,p_term);
 created:=created||jsonb_build_array(jsonb_build_object('gradebookId',bk.ma_bang_diem,'classId',a.ma_lop,'className',a.ten_lop,'subjectId',a.ma_mon,'subjectName',a.ten_mon));
 END IF;
 END LOOP;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADEBOOKS_INITIALIZED','hoc_ky:'||p_term::text);
 result:=jsonb_build_object('created',created,'skipped',skipped);
 INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'GRADEBOOK_INITIALIZE',p_hash,result);
 RETURN result;
END $$;

-- kiem_san_sang_cong_bo: thân giữ nguyên từ 202610220002_adjustment_hardening, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.kiem_san_sang_cong_bo(p_term integer) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE a record; b public.bang_diem; issues jsonb:='[]'::jsonb; missing integer[]; without_result integer[];
  n integer; assignments integer:=0; blocking boolean:=false;
BEGIN
  FOR a IN SELECT pc.ma_lop,pc.ma_mon,l.ten_lop,m.ten_mon
    FROM public.phan_cong_giang_day pc JOIN public.lop l ON l.ma_lop=pc.ma_lop JOIN public.mon_hoc m ON m.ma_mon=pc.ma_mon
    WHERE pc.ma_hoc_ky=p_term ORDER BY l.ten_lop,m.ten_mon,pc.ma_lop,pc.ma_mon LOOP
    assignments:=assignments+1;
    SELECT * INTO b FROM public.bang_diem WHERE ma_lop=a.ma_lop AND ma_mon=a.ma_mon AND ma_hoc_ky=p_term;
    IF NOT FOUND THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('GRADEBOOK_MISSING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,NULL,NULL,NULL));
      blocking:=true; CONTINUE;
    END IF;
    IF b.trang_thai<>'DA_CHOT' THEN
      SELECT count(*)::integer INTO n FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon
        AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan);
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('GRADEBOOK_NOT_LOCKED','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      blocking:=true;
      SELECT count(*)::integer INTO n FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon
        AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)
        AND NOT EXISTS(SELECT 1 FROM public.lich_hieu_luc(b.ma_bang_diem,t.ma_thanh_phan));
      IF n>0 THEN
        issues:=issues||jsonb_build_array(public.van_de_cong_bo('COLUMNS_WITHOUT_DEADLINE','WARNING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      END IF;
    END IF;
    IF b.can_tinh_lai_tong_ket THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('RESULTS_OUTDATED','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,NULL));
      blocking:=true;
    END IF;
    SELECT count(*)::integer INTO n FROM public.phieu_dieu_chinh WHERE ma_bang_diem=b.ma_bang_diem AND trang_thai='CHO_DUYET';
    IF n>0 THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('ADJUSTMENT_PENDING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      blocking:=true;
    END IF;
    SELECT count(*)::integer INTO n FROM public.phieu_nhan_dien WHERE ma_bang_diem=b.ma_bang_diem AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU');
    IF n>0 THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('RECOGNITION_PENDING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      blocking:=true;
    END IF;
    SELECT array_agg(s.ma_hoc_sinh ORDER BY s.ma_hoc_sinh) INTO missing FROM public.hoc_sinh_thieu_o(b.ma_bang_diem) s;
    IF missing IS NOT NULL THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('STUDENT_NOT_IN_GRADEBOOK','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,missing,cardinality(missing)));
      blocking:=true;
    END IF;
    IF b.trang_thai='DA_CHOT' THEN
      SELECT array_agg(hs.ma_hoc_sinh ORDER BY hs.ma_hoc_sinh) INTO without_result
      FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs
      WHERE hs.con_hoc
        AND NOT (hs.ma_hoc_sinh=ANY(coalesce(missing,'{}'::integer[])))
        AND EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=b.ma_bang_diem
          AND d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.trang_thai<>'MIEN')
        AND NOT EXISTS(SELECT 1 FROM public.ket_qua_tong_ket k WHERE k.ma_hoc_sinh=hs.ma_hoc_sinh
          AND k.ma_mon=b.ma_mon AND k.ma_hoc_ky=b.ma_hoc_ky);
      IF without_result IS NOT NULL THEN
        issues:=issues||jsonb_build_array(public.van_de_cong_bo('RESULTS_MISSING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,without_result,cardinality(without_result)));
        blocking:=true;
      END IF;
    END IF;
  END LOOP;
  RETURN jsonb_build_object('ready',assignments>0 AND NOT blocking,'issues',issues);
END $$;

-- tao_lo_nhan_dien: thân giữ nguyên từ 202610200001_recognition_batches, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.tao_lo_nhan_dien(
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
  SELECT count(*)::integer INTO active_rows FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky)
  WHERE con_hoc;
  IF roster_rows <> active_rows
     OR (SELECT count(DISTINCT (e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT min((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> 1
     OR (SELECT max((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(DISTINCT (e->>'studentId')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(*) FROM jsonb_array_elements(p_roster) e
         JOIN public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs ON hs.ma_hoc_sinh=(e->>'studentId')::integer
  AND hs.con_hoc AND hs.ho_ten=(e->>'fullName')) <> roster_rows THEN
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

-- tao_phieu_nhan_dien: thân giữ nguyên từ 202610120002_ticket_cancel, danh sách học sinh lấy qua hoc_sinh_cua_lop.
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
  SELECT count(*)::integer INTO active_rows FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky)
  WHERE con_hoc;
  -- n = sĩ số đang học; STT liên tục 1..n không trùng; học sinh không trùng, thuộc lớp, đang học, đúng họ tên.
  IF roster_rows <> active_rows
     OR (SELECT count(DISTINCT (e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT min((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> 1
     OR (SELECT max((e->>'stt')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(DISTINCT (e->>'studentId')::integer) FROM jsonb_array_elements(p_roster) e) <> roster_rows
     OR (SELECT count(*) FROM jsonb_array_elements(p_roster) e
         JOIN public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs ON hs.ma_hoc_sinh=(e->>'studentId')::integer
  AND hs.con_hoc AND hs.ho_ten=(e->>'fullName')) <> roster_rows THEN
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

-- tao_luoi_diem_noi_bo: thân giữ nguyên từ 202610210001_semester_deadlines, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.tao_luoi_diem_noi_bo(p_actor integer,p_lop integer,p_mon integer,p_hoc_ky integer)
RETURNS public.bang_diem LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE v_book public.bang_diem;
BEGIN
 IF NOT EXISTS (
 SELECT 1 FROM public.lop l JOIN public.hoc_ky hk ON hk.ma_nam_hoc = l.ma_nam_hoc
 WHERE l.ma_lop = p_lop AND hk.ma_hoc_ky = p_hoc_ky
 ) THEN
 RAISE EXCEPTION 'GRADEBOOK_YEAR_MISMATCH' USING ERRCODE = '23514';
 END IF;
 SELECT * INTO v_book FROM public.bang_diem WHERE ma_lop = p_lop AND ma_mon = p_mon AND ma_hoc_ky = p_hoc_ky;
 IF FOUND THEN
 -- A retry never overwrites cells, reopens a locked book or duplicates audit.
 RETURN v_book;
 END IF;
 IF NOT EXISTS (SELECT 1 FROM public.hoc_sinh_cua_lop(p_lop, p_hoc_ky) s WHERE s.con_hoc)
 OR NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon = p_mon) THEN
 RAISE EXCEPTION 'GRADEBOOK_EMPTY_ROSTER_OR_COMPONENTS' USING ERRCODE = '23514';
 END IF;
 INSERT INTO public.bang_diem (ma_lop, ma_mon, ma_hoc_ky) VALUES (p_lop, p_mon, p_hoc_ky) RETURNING * INTO v_book;
 INSERT INTO public.diem_thanh_phan (ma_bang_diem, ma_hoc_sinh, ma_thanh_phan, gia_tri, trang_thai, nguon_nhap)
 SELECT v_book.ma_bang_diem, hs.ma_hoc_sinh, tp.ma_thanh_phan, NULL, 'CHUA_CO', 'NHAP_TAY'
 FROM public.hoc_sinh_cua_lop(p_lop, p_hoc_ky) hs CROSS JOIN public.thanh_phan_diem tp
 WHERE hs.con_hoc AND tp.ma_mon = p_mon;
 INSERT INTO public.nhat_ky_bao_mat (ma_tac_nhan, hanh_dong, doi_tuong)
 VALUES (p_actor, 'GRADEBOOK_CREATED', 'bang_diem:' || v_book.ma_bang_diem);
 RETURN v_book;
END $$;

-- them_hoc_sinh_sau_chot: thân giữ nguyên từ 202610210003_cell_exempt, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.them_hoc_sinh_sau_chot(p_phien text,p_book integer,p_student integer,p_reason text,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; prior public.khoa_idempotency; comp record; actor_id integer; reason text; new_id bigint;
  created integer:=0; exempted integer:=0; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  reason:=btrim(coalesce(p_reason,''));
  IF p_student IS NULL OR p_student<1 OR length(reason) NOT BETWEEN 1 AND 500 OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_LATE_STUDENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='LATE_STUDENT' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
    RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) s WHERE s.ma_hoc_sinh=p_student AND s.con_hoc) THEN
    RAISE EXCEPTION 'STUDENT_NOT_IN_CLASS' USING ERRCODE='23514'; END IF;
  PERFORM set_config('qld.cho_phep_o_mien','on',true);
  FOR comp IN SELECT tp.ma_thanh_phan FROM public.thanh_phan_diem tp WHERE tp.ma_mon=b.ma_mon
    AND NOT EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=p_book AND d.ma_hoc_sinh=p_student
      AND d.ma_thanh_phan=tp.ma_thanh_phan)
    ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan LOOP
    IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=comp.ma_thanh_phan) THEN
      INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan,gia_tri,trang_thai,nguon_nhap)
      VALUES(p_book,p_student,comp.ma_thanh_phan,NULL,'MIEN','NHAP_TAY') RETURNING ma_diem INTO new_id;
      INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(new_id,'MIEN',reason,actor_id);
      exempted:=exempted+1;
    ELSE
      INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES(p_book,p_student,comp.ma_thanh_phan);
    END IF;
    created:=created+1;
  END LOOP;
  PERFORM set_config('qld.cho_phep_o_mien','off',true);
  IF created>0 THEN UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book; END IF;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'LATE_STUDENT_ADDED','bang_diem:'||p_book||':'||p_student);
  result:=jsonb_build_object('bookId',p_book,'version',b.version+CASE WHEN created>0 THEN 1 ELSE 0 END,
    'createdCells',created,'exemptedCells',exempted);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'LATE_STUDENT',p_hash,result);
  RETURN result;
END $$;

-- tinh_ket_qua_bang_diem: thân giữ nguyên từ 202610220001_adjustments, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.tinh_ket_qua_bang_diem(
  p_phien text,
  p_book integer,
  p_version integer,
  p_reason text,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  pass_fail boolean;
  actor_id integer;
  policy public.chinh_sach_xep_loai;
  prior public.khoa_idempotency;
  student record;
  old_result public.ket_qua_tong_ket;
  saved_result public.ket_qua_tong_ket;
  weight_snapshot jsonb;
  policy_snapshot jsonb;
  full_snapshot jsonb;
  weight_version varchar(20);
  total numeric;
  denominator numeric;
  rounded numeric(3,1);
  classification varchar(20);
  missing jsonb;
  results jsonb := '[]'::jsonb;
  skipped jsonb := '[]'::jsonb;
  exempted jsonb := '[]'::jsonb;
  calculated integer := 0;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_version IS NULL OR p_version < 0
     OR length(btrim(p_reason)) NOT BETWEEN 1 AND 500
     OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_FINAL_RESULT_REQUEST' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;

  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
      AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='FINAL_RESULTS'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;
  IF b.trang_thai<>'DA_CHOT' OR b.version<>p_version THEN
    RAISE EXCEPTION 'GRADEBOOK_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  IF EXISTS (SELECT 1 FROM public.diem_thanh_phan
             WHERE ma_bang_diem=p_book AND trang_thai='CHO_DOI_CHIEU') THEN
    RAISE EXCEPTION 'PENDING_REVIEW' USING ERRCODE='23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon=b.ma_mon)
     OR EXISTS (SELECT 1 FROM public.thanh_phan_diem
                WHERE ma_mon=b.ma_mon AND he_so<=0) THEN
    RAISE EXCEPTION 'INVALID_WEIGHTS' USING ERRCODE='23514';
  END IF;

  IF EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
    RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
  SELECT danh_gia_dat INTO pass_fail FROM public.mon_hoc WHERE ma_mon=b.ma_mon;
  SELECT * INTO policy FROM public.chinh_sach_xep_loai WHERE dang_ap_dung;
  IF NOT FOUND OR NOT EXISTS (SELECT 1 FROM public.tieu_chi_xep_loai
                              WHERE ma_chinh_sach=policy.ma_chinh_sach AND diem_toi_thieu=0.0) THEN
    RAISE EXCEPTION 'CLASSIFICATION_POLICY_UNAVAILABLE' USING ERRCODE='23514';
  END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'componentId',tp.ma_thanh_phan,'name',tp.ten_thanh_phan,
           'coefficient',public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)::text,'required',tp.bat_buoc)
           ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan),'[]'::jsonb),
         ('W-'||substr(md5(string_agg(tp.ma_thanh_phan::text||':'||public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)::text||':'||tp.bat_buoc::text,
                          ',' ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan)),1,18))::varchar(20)
  INTO weight_snapshot,weight_version
  FROM public.thanh_phan_diem tp WHERE tp.ma_mon=b.ma_mon;
  SELECT jsonb_build_object('version',policy.phien_ban,'roundingDigits',policy.so_chu_so_lam_tron,
           'criteria',jsonb_agg(jsonb_build_object('code',c.ma_xep_loai,
             'minimum',c.diem_toi_thieu::text) ORDER BY c.diem_toi_thieu DESC))
  INTO policy_snapshot
  FROM public.tieu_chi_xep_loai c WHERE c.ma_chinh_sach=policy.ma_chinh_sach;
  full_snapshot:=jsonb_build_object('weights',weight_snapshot,'classificationPolicy',policy_snapshot,'assessmentMode',CASE WHEN pass_fail THEN 'PASS_FAIL' ELSE 'NUMERIC' END);

  FOR student IN SELECT hs.ma_hoc_sinh,hs.ho_ten FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs
                 WHERE hs.con_hoc ORDER BY hs.ma_hoc_sinh LOOP
    -- Học sinh được miễn MỌI ô của bảng: không tạo kết quả (khác học sinh bị bỏ qua vì thiếu điểm).
    IF EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=p_book AND d.ma_hoc_sinh=student.ma_hoc_sinh)
       AND NOT EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=p_book
         AND d.ma_hoc_sinh=student.ma_hoc_sinh AND d.trang_thai<>'MIEN') THEN
      exempted:=exempted||jsonb_build_array(jsonb_build_object(
        'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten));
      CONTINUE;
    END IF;
    SELECT coalesce(jsonb_agg(jsonb_build_object('componentId',tp.ma_thanh_phan,'name',tp.ten_thanh_phan)
             ORDER BY tp.thu_tu_hien_thi),'[]'::jsonb)
    INTO missing
    FROM public.thanh_phan_diem tp LEFT JOIN public.diem_thanh_phan d
      ON d.ma_bang_diem=p_book AND d.ma_hoc_sinh=student.ma_hoc_sinh
     AND d.ma_thanh_phan=tp.ma_thanh_phan
    WHERE tp.ma_mon=b.ma_mon AND tp.bat_buoc
      AND (d.ma_diem IS NULL OR (d.trang_thai<>'MIEN' AND (d.gia_tri IS NULL OR d.trang_thai<>'DA_DUYET')));
    IF jsonb_array_length(missing)>0 THEN
      skipped:=skipped||jsonb_build_array(jsonb_build_object(
        'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten,'missingComponents',missing));
      CONTINUE;
    END IF;

    SELECT sum(d.gia_tri*public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)),sum(public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky))
    INTO total,denominator
    FROM public.diem_thanh_phan d JOIN public.thanh_phan_diem tp USING(ma_thanh_phan)
    WHERE d.ma_bang_diem=p_book AND d.ma_hoc_sinh=student.ma_hoc_sinh
      AND tp.ma_mon=b.ma_mon AND d.trang_thai='DA_DUYET' AND d.gia_tri IS NOT NULL;
    IF denominator IS NULL OR denominator<=0 THEN
      skipped:=skipped||jsonb_build_array(jsonb_build_object(
        'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten,'missingComponents','[]'::jsonb));
      CONTINUE;
    END IF;
    rounded:=round(total/denominator,policy.so_chu_so_lam_tron)::numeric(3,1);
    SELECT c.ma_xep_loai INTO classification FROM public.tieu_chi_xep_loai c
    WHERE c.ma_chinh_sach=policy.ma_chinh_sach AND rounded>=c.diem_toi_thieu
    ORDER BY c.diem_toi_thieu DESC LIMIT 1;
    IF pass_fail THEN
      IF total/denominator >= 5.0 THEN rounded:=10.0; classification:='DAT';
      ELSE rounded:=0.0; classification:='CHUA_DAT'; END IF;
    END IF;
    IF classification IS NULL THEN
      RAISE EXCEPTION 'CLASSIFICATION_POLICY_GAP' USING ERRCODE='23514';
    END IF;

    SELECT * INTO old_result FROM public.ket_qua_tong_ket
    WHERE ma_hoc_sinh=student.ma_hoc_sinh AND ma_mon=b.ma_mon AND ma_hoc_ky=b.ma_hoc_ky FOR UPDATE;
    INSERT INTO public.ket_qua_tong_ket(ma_hoc_sinh,ma_mon,ma_hoc_ky,diem_tong_ket,xep_loai,
      phien_ban_he_so,bo_he_so,ngay_tinh)
    VALUES(student.ma_hoc_sinh,b.ma_mon,b.ma_hoc_ky,rounded,classification,weight_version,
      full_snapshot,statement_timestamp())
    ON CONFLICT(ma_hoc_sinh,ma_mon,ma_hoc_ky) DO UPDATE SET
      diem_tong_ket=excluded.diem_tong_ket,xep_loai=excluded.xep_loai,
      phien_ban_he_so=excluded.phien_ban_he_so,bo_he_so=excluded.bo_he_so,ngay_tinh=excluded.ngay_tinh
    RETURNING * INTO saved_result;
    INSERT INTO public.lich_su_tong_ket(ma_ket_qua,nguoi_tinh,diem_cu,xep_loai_cu,bo_he_so_cu,
      diem_moi,xep_loai_moi,bo_he_so_moi,ly_do)
    VALUES(saved_result.ma_ket_qua,actor_id,old_result.diem_tong_ket,old_result.xep_loai,old_result.bo_he_so,
      rounded,classification,full_snapshot,btrim(p_reason));
    calculated:=calculated+1;
    results:=results||jsonb_build_array(jsonb_build_object(
      'id',saved_result.ma_ket_qua::text,'studentId',student.ma_hoc_sinh,'studentName',student.ho_ten,
      'finalScore',rounded::text,'classification',classification,'weightVersion',weight_version,
      'policyVersion',policy.phien_ban,'calculatedAt',to_char(saved_result.ngay_tinh AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"')));
  END LOOP;

  UPDATE public.bang_diem SET can_tinh_lai_tong_ket=false WHERE ma_bang_diem=p_book;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'FINAL_RESULTS_CALCULATED','bang_diem:'||p_book::text);
  result:=jsonb_build_object('gradebookId',p_book,'gradebookVersion',b.version,
    'weightVersion',weight_version,'policyVersion',policy.phien_ban,
    'calculatedStudents',calculated,'skippedStudents',jsonb_array_length(skipped),
    'results',results,'skipped',skipped,
    'exemptedStudents',jsonb_array_length(exempted),'exempted',exempted);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua)
  VALUES(p_idempotency_key,actor_id,'FINAL_RESULTS',p_request_hash,result);
  RETURN result;
END $$;

-- xu_ly_han_nhap_diem: thân giữ nguyên từ 202610210003_cell_exempt, danh sách học sinh lấy qua hoc_sinh_cua_lop.
CREATE OR REPLACE FUNCTION public.xu_ly_han_nhap_diem() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE w record; b public.bang_diem; d public.diem_thanh_phan; n integer:=0;
BEGIN
 IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
 IF NOT pg_try_advisory_xact_lock(714042026) THEN RETURN 0; END IF;
 FOR w IN SELECT bd.ma_bang_diem,t.ma_thanh_phan,t.bat_buoc,e.nguoi_dat
 FROM public.bang_diem bd
 JOIN public.thanh_phan_diem t ON t.ma_mon=bd.ma_mon
 CROSS JOIN LATERAL public.lich_hieu_luc(bd.ma_bang_diem,t.ma_thanh_phan) e
 WHERE bd.trang_thai='DANG_NHAP_LIEU' AND e.dong_luc<=clock_timestamp()
 AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=bd.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)
 ORDER BY bd.ma_bang_diem,t.ma_thanh_phan LIMIT 100 LOOP
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=w.ma_bang_diem FOR UPDATE;
 IF b.trang_thai='DA_CHOT' OR EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=w.ma_bang_diem AND ma_thanh_phan=w.ma_thanh_phan) THEN CONTINUE; END IF;
 -- Sync newly enrolled students before assigning an explicit zero to missing grades.
 INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan)
 SELECT b.ma_bang_diem,hs.ma_hoc_sinh,w.ma_thanh_phan FROM public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs WHERE hs.con_hoc
 ON CONFLICT(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) DO NOTHING;
 IF w.bat_buoc THEN
 FOR d IN SELECT g.* FROM public.diem_thanh_phan g JOIN public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs USING(ma_hoc_sinh)
 WHERE g.ma_bang_diem=b.ma_bang_diem AND g.ma_thanh_phan=w.ma_thanh_phan AND hs.con_hoc AND g.trang_thai<>'MIEN' AND (g.gia_tri IS NULL OR g.trang_thai<>'DA_DUYET') FOR UPDATE OF g LOOP
 UPDATE public.diem_thanh_phan SET gia_tri=0.0,trang_thai='DA_DUYET',nguon_nhap='NHAP_TAY' WHERE ma_diem=d.ma_diem;
 INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
 VALUES(d.ma_diem,w.nguoi_dat,d.gia_tri,0.0,'Hệ thống tự ghi 0 do hết hạn nhập điểm do nhà trường đặt; ô thiếu hoặc chưa được duyệt.');
 END LOOP;
 END IF;
 UPDATE public.phieu_nhan_dien SET trang_thai='LOI',ma_loi='GRADE_DEADLINE_EXPIRED',version=version+1 WHERE ma_bang_diem=b.ma_bang_diem AND ma_thanh_phan=w.ma_thanh_phan AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU');
 INSERT INTO public.chot_cot_diem(ma_bang_diem,ma_thanh_phan,nguoi_chot) VALUES(b.ma_bang_diem,w.ma_thanh_phan,w.nguoi_dat);
 UPDATE public.bang_diem SET version=version+1,trang_thai=CASE WHEN NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)) THEN 'DA_CHOT'::public."TrangThaiBangDiem" ELSE trang_thai END WHERE ma_bang_diem=b.ma_bang_diem;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(NULL,'GRADE_COLUMN_AUTO_LOCKED',b.ma_bang_diem::text||':'||w.ma_thanh_phan::text);
 n:=n+1;
 END LOOP;
 RETURN n;
END $$;

COMMIT;
