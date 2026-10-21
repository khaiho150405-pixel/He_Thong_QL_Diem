-- Lịch nhập điểm mặc định theo (học kỳ, TX/GK/CK) và khởi tạo bảng điểm hàng loạt (ADR-0014 bổ sung).
-- Sửa lỗi: hết hạn chỉ ghi 0 cho cột bắt buộc. Lịch riêng (bảng, cột) ghi đè lịch học kỳ.
BEGIN;

CREATE TABLE public.lich_nhap_hoc_ky (
 ma_hoc_ky integer NOT NULL REFERENCES public.hoc_ky ON DELETE RESTRICT,
 loai_he_so varchar(2) NOT NULL CHECK (loai_he_so IN ('TX','GK','CK')),
 mo_luc timestamptz(6) NOT NULL,
 dong_luc timestamptz(6) NOT NULL CHECK(dong_luc>mo_luc),
 nguoi_dat integer NOT NULL REFERENCES public.nguoi_dung ON DELETE RESTRICT,
 version integer NOT NULL DEFAULT 1,
 PRIMARY KEY(ma_hoc_ky,loai_he_so)
);
CREATE INDEX lich_nhap_hoc_ky_dong_luc_idx ON public.lich_nhap_hoc_ky(dong_luc);
GRANT SELECT ON public.lich_nhap_hoc_ky TO app_runtime;

-- Lịch hiệu lực của một cột trong một bảng: lịch riêng nếu có, không thì lịch học kỳ theo loai_he_so của thành phần.
CREATE FUNCTION public.lich_hieu_luc(p_book integer,p_component integer)
RETURNS TABLE(mo_luc timestamptz,dong_luc timestamptz,nguon text,nguoi_dat integer,version integer)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
 SELECT r.mo_luc,r.dong_luc,'RIENG'::text,r.nguoi_dat,r.version
 FROM public.lich_nhap_diem r WHERE r.ma_bang_diem=p_book AND r.ma_thanh_phan=p_component
 UNION ALL
 SELECT h.mo_luc,h.dong_luc,'HOC_KY'::text,h.nguoi_dat,h.version
 FROM public.bang_diem b
 JOIN public.thanh_phan_diem t ON t.ma_thanh_phan=p_component AND t.ma_mon=b.ma_mon
 JOIN public.lich_nhap_hoc_ky h ON h.ma_hoc_ky=b.ma_hoc_ky AND h.loai_he_so=t.loai_he_so
 WHERE b.ma_bang_diem=p_book
 AND NOT EXISTS(SELECT 1 FROM public.lich_nhap_diem r WHERE r.ma_bang_diem=p_book AND r.ma_thanh_phan=p_component)
$$;
REVOKE ALL ON FUNCTION public.lich_hieu_luc(integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lich_hieu_luc(integer,integer) TO app_runtime;

CREATE OR REPLACE FUNCTION public.kiem_thoi_gian_nhap(p_book integer,p_component integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE w record;
BEGIN
 SELECT * INTO w FROM public.lich_hieu_luc(p_book,p_component);
 IF FOUND AND (clock_timestamp()<w.mo_luc OR clock_timestamp()>=w.dong_luc) THEN
 RAISE EXCEPTION 'GRADE_ENTRY_WINDOW_CLOSED' USING ERRCODE='23514'; END IF;
END $$;

-- Đặt lịch riêng (bảng, cột): điều kiện "đã hết hạn thì không sửa" xét theo lịch hiệu lực.
CREATE OR REPLACE FUNCTION public.dat_lich_nhap_diem(p_session text,p_book integer,p_component integer,p_open timestamptz,p_close timestamptz,p_version integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; b public.bang_diem; current_version integer;
BEGIN
 SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
 WHERE s.ma_bam=p_session AND u.vai_tro='QUAN_TRI_VIEN' AND u.trang_thai AND s.het_han>clock_timestamp() AND s.hoat_dong_cuoi>clock_timestamp()-interval '30 minutes';
 IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=p_book FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
 IF b.trang_thai='DA_CHOT' OR EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component) OR EXISTS(SELECT 1 FROM public.hoc_ky WHERE ma_hoc_ky=b.ma_hoc_ky AND da_cong_bo) THEN
 RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon=b.ma_mon AND ma_thanh_phan=p_component) THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
 SELECT version INTO current_version FROM public.lich_nhap_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component;
 IF p_version IS NULL OR p_version<>coalesce(current_version,0) THEN RAISE EXCEPTION 'DEADLINE_VERSION_CONFLICT' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM public.lich_hieu_luc(p_book,p_component) e WHERE e.dong_luc<=clock_timestamp()) THEN RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF p_open IS NULL OR p_close IS NULL OR p_close<=p_open OR p_close<=clock_timestamp() THEN RAISE EXCEPTION 'INVALID_ENTRY_WINDOW' USING ERRCODE='23514'; END IF;
 INSERT INTO public.lich_nhap_diem VALUES(p_book,p_component,p_open,p_close,actor_id,1)
 ON CONFLICT(ma_bang_diem,ma_thanh_phan) DO UPDATE SET mo_luc=EXCLUDED.mo_luc,dong_luc=EXCLUDED.dong_luc,nguoi_dat=actor_id,version=public.lich_nhap_diem.version+1;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADE_DEADLINE_CONFIGURED',p_book::text||':'||p_component::text);
END $$;

-- Đặt lịch mặc định của học kỳ cho một loại điểm (TX/GK/CK).
CREATE FUNCTION public.dat_lich_nhap_hoc_ky(p_session text,p_term integer,p_type text,p_open timestamptz,p_close timestamptz,p_version integer) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; t public.hoc_ky; w public.lich_nhap_hoc_ky;
BEGIN
 SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
 WHERE s.ma_bam=p_session AND u.vai_tro='QUAN_TRI_VIEN' AND u.trang_thai AND s.het_han>clock_timestamp() AND s.hoat_dong_cuoi>clock_timestamp()-interval '30 minutes';
 IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT * INTO t FROM public.hoc_ky WHERE ma_hoc_ky=p_term FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
 IF t.da_cong_bo THEN RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
 IF p_type IS NULL OR p_type NOT IN ('TX','GK','CK') THEN RAISE EXCEPTION 'INVALID_ENTRY_WINDOW' USING ERRCODE='23514'; END IF;
 SELECT * INTO w FROM public.lich_nhap_hoc_ky WHERE ma_hoc_ky=p_term AND loai_he_so=p_type;
 IF p_version IS NULL OR p_version<>coalesce(w.version,0) THEN RAISE EXCEPTION 'DEADLINE_VERSION_CONFLICT' USING ERRCODE='23514'; END IF;
 IF w.dong_luc<=clock_timestamp() THEN RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF p_open IS NULL OR p_close IS NULL OR p_close<=p_open OR p_close<=clock_timestamp() THEN RAISE EXCEPTION 'INVALID_ENTRY_WINDOW' USING ERRCODE='23514'; END IF;
 INSERT INTO public.lich_nhap_hoc_ky VALUES(p_term,p_type,p_open,p_close,actor_id,1)
 ON CONFLICT(ma_hoc_ky,loai_he_so) DO UPDATE SET mo_luc=EXCLUDED.mo_luc,dong_luc=EXCLUDED.dong_luc,nguoi_dat=actor_id,version=public.lich_nhap_hoc_ky.version+1;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'SEMESTER_DEADLINE_CONFIGURED',p_term::text||':'||p_type);
END $$;
REVOKE ALL ON FUNCTION public.dat_lich_nhap_hoc_ky(text,integer,text,timestamptz,timestamptz,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dat_lich_nhap_hoc_ky(text,integer,text,timestamptz,timestamptz,integer) TO app_runtime;

-- Hết hạn: duyệt mọi cặp (bảng đang nhập × thành phần) có hạn hiệu lực đã qua. Chỉ cột BẮT BUỘC mới bị ghi 0;
-- cột không bắt buộc giữ ô trống (NULL/CHUA_CO), không lịch sử, nhưng vẫn bị chốt.
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
 SELECT b.ma_bang_diem,hs.ma_hoc_sinh,w.ma_thanh_phan FROM public.hoc_sinh hs WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
 ON CONFLICT(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) DO NOTHING;
 IF w.bat_buoc THEN
 FOR d IN SELECT g.* FROM public.diem_thanh_phan g JOIN public.hoc_sinh hs USING(ma_hoc_sinh)
 WHERE g.ma_bang_diem=b.ma_bang_diem AND g.ma_thanh_phan=w.ma_thanh_phan AND hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND (g.gia_tri IS NULL OR g.trang_thai<>'DA_DUYET') FOR UPDATE OF g LOOP
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

-- Phần tạo lưới của tao_luoi_diem_trong tách thành hàm nội bộ (không GRANT cho runtime); kiểm quyền do hàm gọi làm.
CREATE FUNCTION public.tao_luoi_diem_noi_bo(p_actor integer,p_lop integer,p_mon integer,p_hoc_ky integer)
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
 IF NOT EXISTS (SELECT 1 FROM public.hoc_sinh WHERE ma_lop = p_lop AND dang_theo_hoc)
 OR NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem WHERE ma_mon = p_mon) THEN
 RAISE EXCEPTION 'GRADEBOOK_EMPTY_ROSTER_OR_COMPONENTS' USING ERRCODE = '23514';
 END IF;
 INSERT INTO public.bang_diem (ma_lop, ma_mon, ma_hoc_ky) VALUES (p_lop, p_mon, p_hoc_ky) RETURNING * INTO v_book;
 INSERT INTO public.diem_thanh_phan (ma_bang_diem, ma_hoc_sinh, ma_thanh_phan, gia_tri, trang_thai, nguon_nhap)
 SELECT v_book.ma_bang_diem, hs.ma_hoc_sinh, tp.ma_thanh_phan, NULL, 'CHUA_CO', 'NHAP_TAY'
 FROM public.hoc_sinh hs CROSS JOIN public.thanh_phan_diem tp
 WHERE hs.ma_lop = p_lop AND hs.dang_theo_hoc AND tp.ma_mon = p_mon;
 INSERT INTO public.nhat_ky_bao_mat (ma_tac_nhan, hanh_dong, doi_tuong)
 VALUES (p_actor, 'GRADEBOOK_CREATED', 'bang_diem:' || v_book.ma_bang_diem);
 RETURN v_book;
END $$;
REVOKE ALL ON FUNCTION public.tao_luoi_diem_noi_bo(integer,integer,integer,integer) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.tao_luoi_diem_trong(
  p_phien text, p_lop integer, p_mon integer, p_hoc_ky integer
) RETURNS SETOF public.bang_diem
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
DECLARE
  v_actor integer;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE = '25001';
  END IF;
  SELECT u.ma_nguoi_dung INTO v_actor
  FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING (ma_nguoi_dung)
  WHERE s.ma_bam = p_phien AND u.trang_thai AND u.vai_tro = 'GIAO_VIEN'
    AND s.het_han > statement_timestamp()
    AND s.hoat_dong_cuoi > statement_timestamp() - interval '30 minutes';
  IF v_actor IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien = v_actor AND pc.ma_lop = p_lop
      AND pc.ma_mon = p_mon AND pc.ma_hoc_ky = p_hoc_ky
  ) THEN
    RAISE EXCEPTION 'GRADEBOOK_FORBIDDEN' USING ERRCODE = '42501';
  END IF;
  RETURN NEXT public.tao_luoi_diem_noi_bo(v_actor, p_lop, p_mon, p_hoc_ky);
END $$;

-- QTV khởi tạo mọi bảng điểm còn thiếu của một học kỳ. Chạy lại an toàn: bảng đã có không bị đụng tới.
CREATE FUNCTION public.khoi_tao_bang_diem_hoc_ky(p_phien text,p_term integer,p_idem text,p_hash text) RETURNS jsonb
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
 IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_lop=a.ma_lop AND dang_theo_hoc) THEN
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
REVOKE ALL ON FUNCTION public.khoi_tao_bang_diem_hoc_ky(text,integer,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.khoi_tao_bang_diem_hoc_ky(text,integer,text,text) TO app_runtime;
COMMIT;
-- Forward-only rollback: không xóa lịch học kỳ, bảng điểm đã khởi tạo hay nhật ký; thu hồi EXECUTE bằng migration mới nếu cần.
