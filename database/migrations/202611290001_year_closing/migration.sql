-- Quyết định chủ dự án 26/11/2026 (ADR-0022): đóng năm học để dữ liệu năm cũ chỉ còn xem và thống kê.
-- Rollback: gỡ các trigger year_closed_guard, a_year_closed_guard, các hàm mới và bảng lich_su_dong_nam, bỏ cột
-- da_dong_luc rồi cấp lại UPDATE trên nam_hoc cho app_runtime. Không có dữ liệu cũ bị sửa.
BEGIN;

ALTER TABLE public.nam_hoc ADD COLUMN da_dong_luc timestamptz(6);
ALTER TABLE public.nam_hoc ADD CONSTRAINT nam_hoc_dong_khong_hien_hanh CHECK (NOT hien_hanh OR da_dong_luc IS NULL);

-- Runtime chỉ sửa được thông tin danh mục; trạng thái đóng chỉ đổi qua hàm.
REVOKE UPDATE ON public.nam_hoc FROM app_runtime;
GRANT UPDATE (ten, ngay_bat_dau, ngay_ket_thuc, hien_hanh) ON public.nam_hoc TO app_runtime;

CREATE TABLE public.lich_su_dong_nam (
  ma bigserial PRIMARY KEY,
  ma_nam_hoc integer NOT NULL REFERENCES public.nam_hoc(ma_nam_hoc) ON DELETE RESTRICT ON UPDATE RESTRICT,
  hanh_dong varchar(10) NOT NULL CHECK (hanh_dong IN ('DONG','MO_LAI')),
  ly_do varchar(500) NOT NULL CHECK (length(btrim(ly_do)) BETWEEN 1 AND 500),
  nguoi_thuc_hien integer NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  thoi_diem timestamptz(6) NOT NULL DEFAULT now()
);
CREATE INDEX lich_su_dong_nam_nam_idx ON public.lich_su_dong_nam(ma_nam_hoc, ma);
REVOKE ALL ON public.lich_su_dong_nam FROM PUBLIC;
GRANT SELECT ON public.lich_su_dong_nam TO app_runtime;

CREATE FUNCTION public.khong_sua_lich_su_dong_nam() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  RAISE EXCEPTION 'APPEND_ONLY' USING ERRCODE='23514';
END $$;
CREATE TRIGGER year_history_append_only BEFORE UPDATE OR DELETE ON public.lich_su_dong_nam
  FOR EACH ROW EXECUTE FUNCTION public.khong_sua_lich_su_dong_nam();

CREATE FUNCTION public.chan_sua_nam_da_dong() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF TG_OP='INSERT' THEN
    IF NEW.da_dong_luc IS NOT NULL THEN RAISE EXCEPTION 'YEAR_CLOSED' USING ERRCODE='23514'; END IF;
    RETURN NEW;
  END IF;
  IF OLD.da_dong_luc IS NOT NULL AND (TG_OP='DELETE'
     OR (NEW.da_dong_luc IS NOT DISTINCT FROM OLD.da_dong_luc AND to_jsonb(NEW) IS DISTINCT FROM to_jsonb(OLD))) THEN
    RAISE EXCEPTION 'YEAR_CLOSED' USING ERRCODE='23514';
  END IF;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER year_closed_guard BEFORE INSERT OR UPDATE OR DELETE ON public.nam_hoc
  FOR EACH ROW EXECUTE FUNCTION public.chan_sua_nam_da_dong();

-- Chặn mọi ghi vào dữ liệu thuộc năm đã đóng, kể cả bỏ công bố học kỳ.
CREATE FUNCTION public.chan_ghi_nam_da_dong() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE entries jsonb[]:='{}'; entry jsonb; target integer;
BEGIN
  IF TG_OP<>'INSERT' THEN entries:=entries||to_jsonb(OLD); END IF;
  IF TG_OP<>'DELETE' THEN entries:=entries||to_jsonb(NEW); END IF;
  FOREACH entry IN ARRAY entries LOOP
    target:=CASE TG_ARGV[0]
      WHEN 'nam' THEN (entry->>'ma_nam_hoc')::integer
      WHEN 'hoc_ky' THEN (SELECT h.ma_nam_hoc FROM public.hoc_ky h WHERE h.ma_hoc_ky=(entry->>'ma_hoc_ky')::integer)
      WHEN 'bang' THEN (SELECT h.ma_nam_hoc FROM public.bang_diem b JOIN public.hoc_ky h USING(ma_hoc_ky)
        WHERE b.ma_bang_diem=(entry->>'ma_bang_diem')::integer)
    END;
    IF EXISTS(SELECT 1 FROM public.nam_hoc n WHERE n.ma_nam_hoc=target AND n.da_dong_luc IS NOT NULL) THEN
      RAISE EXCEPTION 'YEAR_CLOSED' USING ERRCODE='23514';
    END IF;
  END LOOP;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;

-- Tên bắt đầu bằng "a_" để chạy trước các trigger khác và trả đúng nguyên nhân.
DO $$
DECLARE t record;
BEGIN
  FOR t IN SELECT * FROM (VALUES
    ('hoc_ky','nam','INSERT OR UPDATE OR DELETE'),
    ('lop','nam','INSERT OR UPDATE OR DELETE'),
    ('hoc_sinh_lop','nam','INSERT OR UPDATE OR DELETE'),
    ('phan_cong_giang_day','hoc_ky','INSERT OR UPDATE OR DELETE'),
    ('thoi_khoa_bieu','hoc_ky','INSERT OR UPDATE OR DELETE'),
    ('bang_diem','hoc_ky','INSERT OR UPDATE OR DELETE'),
    ('ket_qua_tong_ket','hoc_ky','INSERT OR UPDATE OR DELETE'),
    ('he_so_hoc_ky','hoc_ky','INSERT OR UPDATE OR DELETE'),
    ('he_so_hoc_ky_chung','hoc_ky','INSERT OR UPDATE OR DELETE'),
    ('lich_nhap_hoc_ky','hoc_ky','INSERT OR UPDATE OR DELETE'),
    ('lich_nhap_diem','bang','INSERT OR UPDATE OR DELETE'),
    ('diem_thanh_phan','bang','INSERT OR UPDATE OR DELETE'),
    ('chot_cot_diem','bang','INSERT OR UPDATE OR DELETE'),
    ('phieu_nhan_dien','bang','INSERT'),
    ('phieu_dieu_chinh','bang','INSERT')
  ) AS v(table_name,scope,events) LOOP
    EXECUTE format('CREATE TRIGGER a_year_closed_guard BEFORE %s ON public.%I FOR EACH ROW EXECUTE FUNCTION public.chan_ghi_nam_da_dong(%L)',
      t.events,t.table_name,t.scope);
  END LOOP;
END $$;

CREATE FUNCTION public.kiem_san_sang_dong_nam(p_year integer) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE y public.nam_hoc; issues jsonb:='[]'::jsonb; r record;
BEGIN
  SELECT * INTO y FROM public.nam_hoc WHERE ma_nam_hoc=p_year;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF y.hien_hanh THEN
    issues:=issues||jsonb_build_object('code','YEAR_IS_CURRENT','severity','BLOCKING','label',y.ten,'count',1);
  END IF;
  FOR r IN SELECT h.ten FROM public.hoc_ky h WHERE h.ma_nam_hoc=p_year AND NOT h.da_cong_bo
      AND (EXISTS(SELECT 1 FROM public.phan_cong_giang_day p WHERE p.ma_hoc_ky=h.ma_hoc_ky)
        OR EXISTS(SELECT 1 FROM public.bang_diem b WHERE b.ma_hoc_ky=h.ma_hoc_ky))
      ORDER BY h.thu_tu LOOP
    issues:=issues||jsonb_build_object('code','TERM_NOT_PUBLISHED','severity','BLOCKING','label',r.ten,'count',1);
  END LOOP;
  FOR r IN SELECT v.code,v.total FROM (
      SELECT 'GRADEBOOK_OPEN' AS code,1 AS position,count(*)::integer AS total
        FROM public.bang_diem b JOIN public.hoc_ky h USING(ma_hoc_ky)
        WHERE h.ma_nam_hoc=p_year AND b.trang_thai<>'DA_CHOT'
      UNION ALL
      SELECT 'RECOGNITION_PENDING',2,count(*)::integer FROM public.phieu_nhan_dien p
        JOIN public.bang_diem b USING(ma_bang_diem) JOIN public.hoc_ky h USING(ma_hoc_ky)
        WHERE h.ma_nam_hoc=p_year AND p.trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')
      UNION ALL
      SELECT 'ADJUSTMENT_PENDING',3,count(*)::integer FROM public.phieu_dieu_chinh p
        JOIN public.bang_diem b USING(ma_bang_diem) JOIN public.hoc_ky h USING(ma_hoc_ky)
        WHERE h.ma_nam_hoc=p_year AND p.trang_thai='CHO_DUYET'
    ) v WHERE v.total>0 ORDER BY v.position LOOP
    issues:=issues||jsonb_build_object('code',r.code,'severity','BLOCKING','label',y.ten,'count',r.total);
  END LOOP;
  FOR r IN SELECT l.ten_lop,count(*)::integer AS total FROM public.hoc_sinh_lop g JOIN public.lop l USING(ma_lop)
      WHERE g.ma_nam_hoc=p_year AND g.trang_thai='DANG_HOC' GROUP BY l.ma_lop,l.ten_lop,l.khoi
      ORDER BY l.khoi,l.ten_lop LOOP
    issues:=issues||jsonb_build_object('code','STUDENTS_NOT_PROMOTED','severity','BLOCKING','label',r.ten_lop,'count',r.total);
  END LOOP;
  IF y.ngay_ket_thuc>(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date THEN
    issues:=issues||jsonb_build_object('code','YEAR_NOT_ENDED','severity','WARNING','label',y.ten,'count',1);
  END IF;
  RETURN jsonb_build_object(
    'ready',NOT EXISTS(SELECT 1 FROM jsonb_array_elements(issues) i WHERE i->>'severity'='BLOCKING'),
    'issues',issues);
END $$;
REVOKE ALL ON FUNCTION public.kiem_san_sang_dong_nam(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.kiem_san_sang_dong_nam(integer) TO app_runtime;

CREATE FUNCTION public.doi_trang_thai_nam_hoc(p_phien text,p_year integer,p_close boolean,p_reason text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; why text; y public.nam_hoc; readiness jsonb; closed_at timestamptz;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  why:=btrim(coalesce(p_reason,''));
  IF p_year IS NULL OR p_close IS NULL OR length(why) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'INVALID_YEAR_CLOSE_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO y FROM public.nam_hoc WHERE ma_nam_hoc=p_year FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF p_close THEN
    IF y.da_dong_luc IS NOT NULL THEN RAISE EXCEPTION 'YEAR_ALREADY_CLOSED' USING ERRCODE='23514'; END IF;
    readiness:=public.kiem_san_sang_dong_nam(p_year);
    IF NOT (readiness->>'ready')::boolean THEN RAISE EXCEPTION 'YEAR_NOT_READY' USING ERRCODE='23514'; END IF;
    closed_at:=now();
  ELSE
    IF y.da_dong_luc IS NULL THEN RAISE EXCEPTION 'YEAR_NOT_CLOSED' USING ERRCODE='23514'; END IF;
  END IF;
  UPDATE public.nam_hoc SET da_dong_luc=closed_at WHERE ma_nam_hoc=p_year;
  INSERT INTO public.lich_su_dong_nam(ma_nam_hoc,hanh_dong,ly_do,nguoi_thuc_hien)
  VALUES(p_year,CASE WHEN p_close THEN 'DONG' ELSE 'MO_LAI' END,why,actor_id);
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
  VALUES(actor_id,CASE WHEN p_close THEN 'ACADEMIC_YEAR_CLOSED' ELSE 'ACADEMIC_YEAR_REOPENED' END,'nam_hoc:'||p_year);
  RETURN jsonb_build_object('yearId',p_year,'closed',p_close);
END $$;
REVOKE ALL ON FUNCTION public.doi_trang_thai_nam_hoc(text,integer,boolean,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.doi_trang_thai_nam_hoc(text,integer,boolean,text) TO app_runtime;

COMMIT;
