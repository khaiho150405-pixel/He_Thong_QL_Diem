-- Điều chỉnh điểm sau chốt (ADR-0017): "phiếu điều chỉnh" theo bảng điểm, QTV duyệt cả phiếu trong một giao dịch.
-- Cột đã chốt vẫn append-only: chỉ hàm duyệt_phieu_dieu_chinh (đặt cờ giao dịch cục bộ qld.dieu_chinh_sau_chot) mới ghi được
-- vào ô của cột đã chốt, mỗi lần có lich_su_sua_diem (và lich_su_mien_diem khi đổi Miễn). Runtime không có quyền UPDATE ô.
--
-- ROLLBACK (chỉ tiến): không xóa phiếu/dòng điều chỉnh đã có vì là bằng chứng. Muốn gỡ tính năng, tạo migration mới thu hồi
-- EXECUTE của bốn hàm *_phieu_dieu_chinh và khôi phục kiem_cot_diem (202610040001_school_workflow),
-- tinh_ket_qua_bang_diem (202610210003_cell_exempt), kiem_san_sang_cong_bo (202610210004_publish_readiness).
BEGIN;

CREATE TYPE public."TrangThaiPhieuDieuChinh" AS ENUM ('CHO_DUYET','DA_DUYET','TU_CHOI','DA_HUY');

ALTER TABLE public.bang_diem ADD COLUMN can_tinh_lai_tong_ket boolean NOT NULL DEFAULT false;

CREATE TABLE public.phieu_dieu_chinh (
  ma bigserial PRIMARY KEY,
  ma_bang_diem integer NOT NULL REFERENCES public.bang_diem(ma_bang_diem) ON DELETE RESTRICT,
  nguoi_gui integer NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT,
  ly_do varchar(500) NOT NULL CHECK (length(btrim(ly_do)) > 0),
  trang_thai public."TrangThaiPhieuDieuChinh" NOT NULL DEFAULT 'CHO_DUYET',
  thoi_diem_gui timestamptz(6) NOT NULL DEFAULT now(),
  nguoi_xu_ly integer REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT,
  thoi_diem_xu_ly timestamptz(6),
  ly_do_xu_ly varchar(500),
  phien_ban_bang_khi_gui integer NOT NULL,
  version integer NOT NULL DEFAULT 1,
  CONSTRAINT phieu_dieu_chinh_xu_ly_day_du CHECK (
    (trang_thai = 'CHO_DUYET' AND nguoi_xu_ly IS NULL AND thoi_diem_xu_ly IS NULL AND ly_do_xu_ly IS NULL)
    OR (trang_thai <> 'CHO_DUYET' AND nguoi_xu_ly IS NOT NULL AND thoi_diem_xu_ly IS NOT NULL)),
  CONSTRAINT phieu_dieu_chinh_tu_choi_co_ly_do CHECK (
    trang_thai <> 'TU_CHOI' OR (ly_do_xu_ly IS NOT NULL AND length(btrim(ly_do_xu_ly)) > 0))
);
-- Mỗi bảng chỉ có một phiếu đang chờ duyệt.
CREATE UNIQUE INDEX phieu_dieu_chinh_mot_cho_duyet ON public.phieu_dieu_chinh(ma_bang_diem) WHERE trang_thai = 'CHO_DUYET';
CREATE INDEX phieu_dieu_chinh_trang_thai_idx ON public.phieu_dieu_chinh(trang_thai, ma DESC);
CREATE INDEX phieu_dieu_chinh_bang_idx ON public.phieu_dieu_chinh(ma_bang_diem, ma DESC);

CREATE TABLE public.dong_dieu_chinh (
  ma bigserial PRIMARY KEY,
  ma_phieu bigint NOT NULL REFERENCES public.phieu_dieu_chinh(ma) ON DELETE RESTRICT,
  ma_diem bigint NOT NULL REFERENCES public.diem_thanh_phan(ma_diem) ON DELETE RESTRICT,
  gia_tri_cu numeric(3,1),
  trang_thai_cu public."TrangThaiDiem" NOT NULL,
  gia_tri_moi numeric(3,1),
  mien_moi boolean NOT NULL,
  ghi_chu varchar(200),
  CONSTRAINT dong_dieu_chinh_gia_tri CHECK (
    (gia_tri_cu IS NULL OR gia_tri_cu BETWEEN 0 AND 10) AND (gia_tri_moi IS NULL OR gia_tri_moi BETWEEN 0 AND 10)),
  CONSTRAINT dong_dieu_chinh_khong_trong CHECK ((mien_moi AND gia_tri_moi IS NULL) OR (NOT mien_moi AND gia_tri_moi IS NOT NULL)),
  UNIQUE (ma_phieu, ma_diem)
);
CREATE INDEX dong_dieu_chinh_diem_idx ON public.dong_dieu_chinh(ma_diem);

GRANT SELECT ON public.phieu_dieu_chinh, public.dong_dieu_chinh TO app_runtime;

CREATE FUNCTION public.khong_sua_dong_dieu_chinh() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN RAISE EXCEPTION 'ADJUSTMENT_LINES_APPEND_ONLY' USING ERRCODE='23514'; END $$;
CREATE TRIGGER adjustment_lines_append_only BEFORE UPDATE OR DELETE ON public.dong_dieu_chinh
  FOR EACH ROW EXECUTE FUNCTION public.khong_sua_dong_dieu_chinh();
CREATE TRIGGER adjustment_lines_no_truncate BEFORE TRUNCATE ON public.dong_dieu_chinh
  FOR EACH STATEMENT EXECUTE FUNCTION public.khong_sua_dong_dieu_chinh();

-- Phiếu không bị xóa; sau khi đã xử lý thì bất biến.
CREATE FUNCTION public.kiem_phieu_dieu_chinh() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF TG_OP <> 'UPDATE' OR OLD.trang_thai <> 'CHO_DUYET' THEN
    RAISE EXCEPTION 'ADJUSTMENT_IMMUTABLE' USING ERRCODE='23514'; END IF;
  IF NEW.ma <> OLD.ma OR NEW.ma_bang_diem <> OLD.ma_bang_diem OR NEW.nguoi_gui <> OLD.nguoi_gui
     OR NEW.ly_do <> OLD.ly_do OR NEW.thoi_diem_gui <> OLD.thoi_diem_gui
     OR NEW.phien_ban_bang_khi_gui <> OLD.phien_ban_bang_khi_gui THEN
    RAISE EXCEPTION 'ADJUSTMENT_IMMUTABLE' USING ERRCODE='23514'; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER adjustment_state_guard BEFORE UPDATE OR DELETE ON public.phieu_dieu_chinh
  FOR EACH ROW EXECUTE FUNCTION public.kiem_phieu_dieu_chinh();
CREATE TRIGGER adjustment_no_truncate BEFORE TRUNCATE ON public.phieu_dieu_chinh
  FOR EACH STATEMENT EXECUTE FUNCTION public.khong_sua_dong_dieu_chinh();

-- Gửi phiếu: GV phụ trách, chỉ ô thuộc cột đã chốt, một phiếu CHO_DUYET mỗi bảng.
CREATE FUNCTION public.gui_phieu_dieu_chinh(
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
    IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=d.ma_hoc_sinh AND ma_lop=b.ma_lop AND dang_theo_hoc)
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
REVOKE ALL ON FUNCTION public.gui_phieu_dieu_chinh(text,integer,integer,text,jsonb,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.gui_phieu_dieu_chinh(text,integer,integer,text,jsonb,text,text) TO app_runtime;

-- Duyệt cả phiếu trong MỘT giao dịch (QTV): mọi ô phải còn đúng giá trị/trạng thái đã lưu khi gửi, nếu không rollback toàn bộ.
CREATE FUNCTION public.duyet_phieu_dieu_chinh(p_phien text,p_adj bigint,p_version integer,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE a public.phieu_dieu_chinh; b public.bang_diem; l public.dong_dieu_chinh; d public.diem_thanh_phan;
  prior public.khoa_idempotency; actor_id integer; actor_name text; book_id integer; suffix text; base text; why text; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  IF p_adj IS NULL OR p_adj<1 OR p_version IS NULL OR p_version<0 OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_ADJUSTMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung,u.ten_dang_nhap INTO actor_id,actor_name FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT ma_bang_diem INTO book_id FROM public.phieu_dieu_chinh WHERE ma=p_adj;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=book_id FOR UPDATE;
  SELECT * INTO a FROM public.phieu_dieu_chinh WHERE ma=p_adj FOR UPDATE;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ADJUST_APPROVE' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF a.trang_thai<>'CHO_DUYET' THEN RAISE EXCEPTION 'ADJUSTMENT_NOT_PENDING' USING ERRCODE='23514'; END IF;
  IF a.version<>p_version THEN RAISE EXCEPTION 'ADJUSTMENT_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514'; END IF;
  IF EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
    RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
  PERFORM set_config('qld.dieu_chinh_sau_chot',p_adj::text,true);
  suffix:=' — duyệt bởi '||actor_name;
  FOR l IN SELECT * FROM public.dong_dieu_chinh WHERE ma_phieu=p_adj ORDER BY ma LOOP
    SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=l.ma_diem AND ma_bang_diem=b.ma_bang_diem FOR UPDATE;
    IF NOT FOUND OR d.gia_tri IS DISTINCT FROM l.gia_tri_cu OR d.trang_thai<>l.trang_thai_cu THEN
      RAISE EXCEPTION 'ADJUSTMENT_STALE' USING ERRCODE='23514'; END IF;
    base:='Điều chỉnh sau chốt #'||p_adj||': '||a.ly_do||coalesce('; '||l.ghi_chu,'');
    why:=left(base,greatest(500-length(suffix),1))||suffix;
    IF l.mien_moi THEN
      UPDATE public.diem_thanh_phan SET gia_tri=NULL,trang_thai='MIEN' WHERE ma_diem=l.ma_diem;
    ELSE
      UPDATE public.diem_thanh_phan SET gia_tri=l.gia_tri_moi,trang_thai='DA_DUYET',nguon_nhap='NHAP_TAY' WHERE ma_diem=l.ma_diem;
    END IF;
    INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
    VALUES(l.ma_diem,a.nguoi_gui,l.gia_tri_cu,l.gia_tri_moi,why);
    IF l.mien_moi THEN
      INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(l.ma_diem,'MIEN',why,a.nguoi_gui);
    ELSIF l.trang_thai_cu='MIEN' THEN
      INSERT INTO public.lich_su_mien_diem(ma_diem,hanh_dong,ly_do,nguoi_thuc_hien) VALUES(l.ma_diem,'BO_MIEN',why,a.nguoi_gui);
    END IF;
  END LOOP;
  PERFORM set_config('qld.dieu_chinh_sau_chot','',true);
  UPDATE public.phieu_dieu_chinh SET trang_thai='DA_DUYET',nguoi_xu_ly=actor_id,thoi_diem_xu_ly=statement_timestamp(),version=version+1 WHERE ma=p_adj;
  UPDATE public.bang_diem SET can_tinh_lai_tong_ket=true,version=version+1 WHERE ma_bang_diem=b.ma_bang_diem;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ADJUSTMENT_APPROVED','phieu_dieu_chinh:'||p_adj);
  result:=jsonb_build_object('id',p_adj::text);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ADJUST_APPROVE',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.duyet_phieu_dieu_chinh(text,bigint,integer,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.duyet_phieu_dieu_chinh(text,bigint,integer,text,text) TO app_runtime;

-- Từ chối (QTV, lý do bắt buộc).
CREATE FUNCTION public.tu_choi_phieu_dieu_chinh(p_phien text,p_adj bigint,p_version integer,p_reason text,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE a public.phieu_dieu_chinh; prior public.khoa_idempotency; actor_id integer; reason text; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  reason:=btrim(coalesce(p_reason,''));
  IF p_adj IS NULL OR p_adj<1 OR p_version IS NULL OR p_version<0 OR length(reason) NOT BETWEEN 1 AND 500
     OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_ADJUSTMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO a FROM public.phieu_dieu_chinh WHERE ma=p_adj FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ADJUST_REJECT' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF a.trang_thai<>'CHO_DUYET' THEN RAISE EXCEPTION 'ADJUSTMENT_NOT_PENDING' USING ERRCODE='23514'; END IF;
  IF a.version<>p_version THEN RAISE EXCEPTION 'ADJUSTMENT_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514'; END IF;
  UPDATE public.phieu_dieu_chinh SET trang_thai='TU_CHOI',nguoi_xu_ly=actor_id,thoi_diem_xu_ly=statement_timestamp(),
    ly_do_xu_ly=reason,version=version+1 WHERE ma=p_adj;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ADJUSTMENT_REJECTED','phieu_dieu_chinh:'||p_adj);
  result:=jsonb_build_object('id',p_adj::text);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ADJUST_REJECT',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.tu_choi_phieu_dieu_chinh(text,bigint,integer,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tu_choi_phieu_dieu_chinh(text,bigint,integer,text,text,text) TO app_runtime;

-- Hủy (chỉ GV đã gửi và vẫn được phân công).
CREATE FUNCTION public.huy_phieu_dieu_chinh(p_phien text,p_adj bigint,p_version integer,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE a public.phieu_dieu_chinh; b public.bang_diem; prior public.khoa_idempotency; actor_id integer; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  IF p_adj IS NULL OR p_adj<1 OR p_version IS NULL OR p_version<0 OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_ADJUSTMENT_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO a FROM public.phieu_dieu_chinh WHERE ma=p_adj FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=a.ma_bang_diem;
  IF a.nguoi_gui<>actor_id OR NOT EXISTS(SELECT 1 FROM public.phan_cong_giang_day pc WHERE pc.ma_giao_vien=actor_id
    AND pc.ma_lop=b.ma_lop AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='ADJUST_CANCEL' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  IF a.trang_thai<>'CHO_DUYET' THEN RAISE EXCEPTION 'ADJUSTMENT_NOT_PENDING' USING ERRCODE='23514'; END IF;
  IF a.version<>p_version THEN RAISE EXCEPTION 'ADJUSTMENT_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514'; END IF;
  UPDATE public.phieu_dieu_chinh SET trang_thai='DA_HUY',nguoi_xu_ly=actor_id,thoi_diem_xu_ly=statement_timestamp(),version=version+1 WHERE ma=p_adj;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'ADJUSTMENT_CANCELLED','phieu_dieu_chinh:'||p_adj);
  result:=jsonb_build_object('id',p_adj::text);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'ADJUST_CANCEL',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.huy_phieu_dieu_chinh(text,bigint,integer,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.huy_phieu_dieu_chinh(text,bigint,integer,text,text) TO app_runtime;

-- Trigger ô điểm: cột đã chốt chỉ ghi được khi cờ giao dịch cục bộ qld.dieu_chinh_sau_chot trỏ tới một phiếu đang CHO_DUYET có dòng
-- cho đúng ô này với đúng giá trị/trạng thái mới (cờ do duyet_phieu_dieu_chinh đặt; giả mạo cờ không cho ghi giá trị nào khác).
-- Các kiểm tra khác giữ nguyên từ 202610040001_school_workflow.
CREATE OR REPLACE FUNCTION public.kiem_cot_diem() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; flag text:=coalesce(current_setting('qld.dieu_chinh_sau_chot',true),'');
BEGIN
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=NEW.ma_bang_diem FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=NEW.ma_bang_diem AND ma_thanh_phan=NEW.ma_thanh_phan)
    AND NOT (flag ~ '^[1-9][0-9]{0,17}$' AND EXISTS(
      SELECT 1 FROM public.dong_dieu_chinh l JOIN public.phieu_dieu_chinh p ON p.ma=l.ma_phieu
      WHERE p.ma=flag::bigint AND p.trang_thai='CHO_DUYET' AND p.ma_bang_diem=NEW.ma_bang_diem AND l.ma_diem=NEW.ma_diem
        AND l.gia_tri_moi IS NOT DISTINCT FROM NEW.gia_tri AND l.mien_moi=(NEW.trang_thai='MIEN'))) THEN
 RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF NEW.gia_tri IS NOT NULL AND EXISTS(SELECT 1 FROM public.mon_hoc WHERE ma_mon=b.ma_mon AND danh_gia_dat) AND NEW.gia_tri NOT IN (0.0,10.0) THEN
 RAISE EXCEPTION 'PASS_FAIL_VALUE_REQUIRED' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;

-- Tổng kết: tính xong thì bỏ cờ cần tính lại (phần còn lại giữ nguyên từ 202610210003_cell_exempt).
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

  FOR student IN SELECT hs.ma_hoc_sinh,hs.ho_ten FROM public.hoc_sinh hs
                 WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc ORDER BY hs.ma_hoc_sinh LOOP
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

-- Công bố: bảng đã điều chỉnh sau lần tính gần nhất → RESULTS_OUTDATED (phần còn lại giữ nguyên từ 202610210004_publish_readiness).
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
      FROM public.hoc_sinh hs
      WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
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
COMMIT;
