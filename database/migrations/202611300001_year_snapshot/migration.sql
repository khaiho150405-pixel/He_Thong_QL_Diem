-- Quyết định chủ dự án 26/11/2026 (ADR-0023): bản chốt cuối năm chỉ ghi thêm và thống kê theo năm.
-- Rollback: khôi phục xoa_hoc_sinh và doi_trang_thai_nam_hoc bản trước, gỡ các hàm thống kê, đổi tên
-- tinh_muc_hoc_tap lại thành xep_muc_hoc_tap rồi bỏ ba bảng ban_chot_*. Không sửa dữ liệu điểm.
BEGIN;

CREATE TABLE public.ban_chot_nam (
  ma bigserial PRIMARY KEY,
  ma_nam_hoc integer NOT NULL REFERENCES public.nam_hoc(ma_nam_hoc) ON DELETE RESTRICT ON UPDATE RESTRICT,
  phien_ban integer NOT NULL CHECK (phien_ban>0),
  ten_nam varchar(20) NOT NULL,
  ten_truong varchar(200) NOT NULL,
  ngay_bat_dau date NOT NULL,
  ngay_ket_thuc date NOT NULL,
  nguoi_tao integer NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  thoi_diem timestamptz(6) NOT NULL DEFAULT now(),
  UNIQUE (ma_nam_hoc, phien_ban)
);

-- Không có khóa ngoại tới học sinh, lớp, môn: bản chốt giữ nguyên chữ tại thời điểm đóng năm.
CREATE TABLE public.ban_chot_hoc_sinh (
  ma_ban_chot bigint NOT NULL REFERENCES public.ban_chot_nam(ma) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ma_hoc_ky integer NOT NULL,
  ten_hoc_ky varchar(20) NOT NULL,
  thu_tu smallint NOT NULL,
  ma_hoc_sinh integer NOT NULL,
  ho_ten varchar(100) NOT NULL,
  ngay_sinh date NOT NULL,
  ma_lop integer NOT NULL,
  ten_lop varchar(20) NOT NULL,
  khoi smallint NOT NULL,
  gv_chu_nhiem varchar(100) NOT NULL,
  trang_thai_ghi_danh varchar(20) NOT NULL,
  muc_hoc_tap varchar(10),
  so_mon_diem smallint NOT NULL,
  so_mon_nhan_xet smallint NOT NULL,
  nang_muc boolean NOT NULL,
  PRIMARY KEY (ma_ban_chot, ma_hoc_ky, ma_hoc_sinh)
);
CREATE INDEX ban_chot_hoc_sinh_hs_idx ON public.ban_chot_hoc_sinh(ma_hoc_sinh);

CREATE TABLE public.ban_chot_mon (
  ma_ban_chot bigint NOT NULL,
  ma_hoc_ky integer NOT NULL,
  ma_hoc_sinh integer NOT NULL,
  ma_mon integer NOT NULL,
  ten_mon varchar(100) NOT NULL,
  danh_gia_dat boolean NOT NULL,
  giao_vien varchar(100),
  diem_tong_ket numeric(3,1),
  xep_loai varchar(20),
  thanh_phan jsonb NOT NULL,
  PRIMARY KEY (ma_ban_chot, ma_hoc_ky, ma_hoc_sinh, ma_mon),
  FOREIGN KEY (ma_ban_chot, ma_hoc_ky, ma_hoc_sinh)
    REFERENCES public.ban_chot_hoc_sinh(ma_ban_chot, ma_hoc_ky, ma_hoc_sinh) ON DELETE RESTRICT ON UPDATE RESTRICT
);

REVOKE ALL ON public.ban_chot_nam, public.ban_chot_hoc_sinh, public.ban_chot_mon FROM PUBLIC;
GRANT SELECT ON public.ban_chot_nam, public.ban_chot_hoc_sinh, public.ban_chot_mon TO app_runtime;

-- Ngoại lệ duy nhất: xóa thông tin học sinh (ADR-0020) được ẩn họ tên và ngày sinh trong bản chốt.
CREATE FUNCTION public.khong_sua_ban_chot() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF TG_OP='UPDATE' AND TG_TABLE_NAME='ban_chot_hoc_sinh' AND current_user<>'app_runtime'
     AND current_setting('qld.student_removal',true)=to_jsonb(OLD)->>'ma_hoc_sinh'
     AND to_jsonb(NEW)-'ho_ten'-'ngay_sinh'=to_jsonb(OLD)-'ho_ten'-'ngay_sinh' THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'APPEND_ONLY' USING ERRCODE='23514';
END $$;
CREATE TRIGGER snapshot_append_only BEFORE UPDATE OR DELETE ON public.ban_chot_nam
  FOR EACH ROW EXECUTE FUNCTION public.khong_sua_ban_chot();
CREATE TRIGGER snapshot_append_only BEFORE UPDATE OR DELETE ON public.ban_chot_hoc_sinh
  FOR EACH ROW EXECUTE FUNCTION public.khong_sua_ban_chot();
CREATE TRIGGER snapshot_append_only BEFORE UPDATE OR DELETE ON public.ban_chot_mon
  FOR EACH ROW EXECUTE FUNCTION public.khong_sua_ban_chot();

ALTER FUNCTION public.xep_muc_hoc_tap(integer,integer) RENAME TO tinh_muc_hoc_tap;
REVOKE ALL ON FUNCTION public.tinh_muc_hoc_tap(integer,integer) FROM app_runtime;

CREATE FUNCTION public.ban_chot_dang_dung(p_year integer) RETURNS bigint
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT b.ma FROM public.ban_chot_nam b JOIN public.nam_hoc n USING(ma_nam_hoc)
  WHERE b.ma_nam_hoc=p_year AND n.da_dong_luc IS NOT NULL ORDER BY b.phien_ban DESC LIMIT 1
$$;
REVOKE ALL ON FUNCTION public.ban_chot_dang_dung(integer) FROM PUBLIC;

-- Năm đã đóng trả mức đã chốt; năm còn mở tính như cũ.
CREATE FUNCTION public.xep_muc_hoc_tap(p_student integer,p_term integer) RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT coalesce((
    SELECT jsonb_build_object('level',s.muc_hoc_tap,'numericSubjects',s.so_mon_diem,
      'passFailSubjects',s.so_mon_nhan_xet,'raised',s.nang_muc)
    FROM public.hoc_ky h JOIN public.ban_chot_hoc_sinh s
      ON s.ma_ban_chot=public.ban_chot_dang_dung(h.ma_nam_hoc) AND s.ma_hoc_ky=h.ma_hoc_ky
    WHERE h.ma_hoc_ky=p_term AND s.ma_hoc_sinh=p_student
  ),public.tinh_muc_hoc_tap(p_student,p_term))
$$;
REVOKE ALL ON FUNCTION public.xep_muc_hoc_tap(integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.xep_muc_hoc_tap(integer,integer) TO app_runtime;

CREATE FUNCTION public.du_lieu_hoc_sinh_nam(p_year integer)
RETURNS TABLE(ma_hoc_ky integer,ten_hoc_ky varchar,thu_tu smallint,ma_hoc_sinh integer,ho_ten varchar,ngay_sinh date,
  ma_lop integer,ten_lop varchar,khoi smallint,gv_chu_nhiem varchar,trang_thai_ghi_danh varchar,muc_hoc_tap varchar,
  so_mon_diem smallint,so_mon_nhan_xet smallint,nang_muc boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT DISTINCT ON (h.ma_hoc_ky,s.ma_hoc_sinh)
    h.ma_hoc_ky,h.ten::varchar,h.thu_tu,s.ma_hoc_sinh,hs.ho_ten::varchar,hs.ngay_sinh,l.ma_lop,l.ten_lop::varchar,l.khoi,
    gv.ho_ten::varchar,g.trang_thai::text::varchar,(r.result->>'level')::varchar,(r.result->>'numericSubjects')::smallint,
    (r.result->>'passFailSubjects')::smallint,(r.result->>'raised')::boolean
  FROM public.hoc_ky h
  JOIN (SELECT DISTINCT b.ma_lop,b.ma_hoc_ky FROM public.bang_diem b) k ON k.ma_hoc_ky=h.ma_hoc_ky
  JOIN public.lop l ON l.ma_lop=k.ma_lop
  JOIN public.giao_vien gv ON gv.ma_giao_vien=l.ma_gv_chu_nhiem
  CROSS JOIN LATERAL public.hoc_sinh_cua_lop(k.ma_lop,k.ma_hoc_ky) s
  JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh=s.ma_hoc_sinh
  JOIN public.hoc_sinh_lop g ON g.ma_hoc_sinh=s.ma_hoc_sinh AND g.ma_lop=k.ma_lop
  CROSS JOIN LATERAL (SELECT public.tinh_muc_hoc_tap(s.ma_hoc_sinh,h.ma_hoc_ky) AS result) r
  WHERE h.ma_nam_hoc=p_year AND h.da_cong_bo AND s.con_hoc
  ORDER BY h.ma_hoc_ky,s.ma_hoc_sinh,g.tu_ngay DESC,g.ma DESC
$$;
REVOKE ALL ON FUNCTION public.du_lieu_hoc_sinh_nam(integer) FROM PUBLIC;

CREATE FUNCTION public.du_lieu_mon_nam(p_year integer)
RETURNS TABLE(ma_hoc_ky integer,ma_hoc_sinh integer,ma_mon integer,ten_mon varchar,danh_gia_dat boolean,
  giao_vien varchar,diem_tong_ket numeric,xep_loai varchar,thanh_phan jsonb)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT d.ma_hoc_ky,d.ma_hoc_sinh,m.ma_mon,m.ten_mon::varchar,m.danh_gia_dat,gv.ho_ten::varchar,kq.diem_tong_ket,
    CASE WHEN m.danh_gia_dat THEN kq.xep_loai END::varchar,
    coalesce((SELECT jsonb_agg(jsonb_build_object('name',tp.ten_thanh_phan,'kind',tp.loai_he_so,
        'coefficient',public.he_so_ap_dung(tp.ma_thanh_phan,b.ma_hoc_ky)::text,
        'value',CASE WHEN c.trang_thai='DA_DUYET' THEN c.gia_tri::text END,
        'exempt',coalesce(c.trang_thai='MIEN',false)) ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan)
      FROM public.thanh_phan_diem tp LEFT JOIN public.diem_thanh_phan c ON c.ma_bang_diem=b.ma_bang_diem
        AND c.ma_thanh_phan=tp.ma_thanh_phan AND c.ma_hoc_sinh=d.ma_hoc_sinh
      WHERE tp.ma_mon=b.ma_mon),'[]'::jsonb)
  FROM public.du_lieu_hoc_sinh_nam(p_year) d
  JOIN public.bang_diem b ON b.ma_lop=d.ma_lop AND b.ma_hoc_ky=d.ma_hoc_ky
  JOIN public.mon_hoc m ON m.ma_mon=b.ma_mon
  LEFT JOIN public.phan_cong_giang_day pc ON pc.ma_lop=b.ma_lop AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky
  LEFT JOIN public.giao_vien gv ON gv.ma_giao_vien=pc.ma_giao_vien
  LEFT JOIN public.ket_qua_tong_ket kq ON kq.ma_hoc_sinh=d.ma_hoc_sinh AND kq.ma_mon=b.ma_mon
    AND kq.ma_hoc_ky=d.ma_hoc_ky
$$;
REVOKE ALL ON FUNCTION public.du_lieu_mon_nam(integer) FROM PUBLIC;

CREATE FUNCTION public.lap_ban_chot_nam(p_year integer,p_actor integer) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE snapshot_id bigint;
BEGIN
  INSERT INTO public.ban_chot_nam(ma_nam_hoc,phien_ban,ten_nam,ten_truong,ngay_bat_dau,ngay_ket_thuc,nguoi_tao)
  SELECT n.ma_nam_hoc,
    1+coalesce((SELECT max(b.phien_ban) FROM public.ban_chot_nam b WHERE b.ma_nam_hoc=n.ma_nam_hoc),0),
    n.ten,coalesce((SELECT t.ten_truong FROM public.truong t WHERE t.ma_truong=1),'Chưa khai báo'),
    n.ngay_bat_dau,n.ngay_ket_thuc,p_actor
  FROM public.nam_hoc n WHERE n.ma_nam_hoc=p_year
  RETURNING ma INTO snapshot_id;
  INSERT INTO public.ban_chot_hoc_sinh
  SELECT snapshot_id,d.* FROM public.du_lieu_hoc_sinh_nam(p_year) d;
  INSERT INTO public.ban_chot_mon
  SELECT snapshot_id,d.* FROM public.du_lieu_mon_nam(p_year) d;
  RETURN snapshot_id;
END $$;
REVOKE ALL ON FUNCTION public.lap_ban_chot_nam(integer,integer) FROM PUBLIC;

CREATE FUNCTION public.nguon_hoc_sinh_nam(p_year integer)
RETURNS TABLE(ma_hoc_ky integer,ten_hoc_ky varchar,thu_tu smallint,ma_hoc_sinh integer,ho_ten varchar,ngay_sinh date,
  ma_lop integer,ten_lop varchar,khoi smallint,gv_chu_nhiem varchar,trang_thai_ghi_danh varchar,muc_hoc_tap varchar,
  so_mon_diem smallint,so_mon_nhan_xet smallint,nang_muc boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE snapshot_id bigint:=public.ban_chot_dang_dung(p_year);
BEGIN
  IF snapshot_id IS NULL THEN
    RETURN QUERY SELECT * FROM public.du_lieu_hoc_sinh_nam(p_year);
  ELSE
    RETURN QUERY SELECT s.ma_hoc_ky,s.ten_hoc_ky,s.thu_tu,s.ma_hoc_sinh,s.ho_ten,s.ngay_sinh,s.ma_lop,s.ten_lop,s.khoi,
      s.gv_chu_nhiem,s.trang_thai_ghi_danh,s.muc_hoc_tap,s.so_mon_diem,s.so_mon_nhan_xet,s.nang_muc
      FROM public.ban_chot_hoc_sinh s WHERE s.ma_ban_chot=snapshot_id;
  END IF;
END $$;
REVOKE ALL ON FUNCTION public.nguon_hoc_sinh_nam(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.nguon_hoc_sinh_nam(integer) TO app_runtime;

CREATE FUNCTION public.nguon_mon_nam(p_year integer)
RETURNS TABLE(ma_hoc_ky integer,ma_hoc_sinh integer,ma_mon integer,ten_mon varchar,danh_gia_dat boolean,
  giao_vien varchar,diem_tong_ket numeric,xep_loai varchar,thanh_phan jsonb)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE snapshot_id bigint:=public.ban_chot_dang_dung(p_year);
BEGIN
  IF snapshot_id IS NULL THEN
    RETURN QUERY SELECT * FROM public.du_lieu_mon_nam(p_year);
  ELSE
    RETURN QUERY SELECT s.ma_hoc_ky,s.ma_hoc_sinh,s.ma_mon,s.ten_mon,s.danh_gia_dat,s.giao_vien,
      s.diem_tong_ket::numeric,s.xep_loai,s.thanh_phan
      FROM public.ban_chot_mon s WHERE s.ma_ban_chot=snapshot_id;
  END IF;
END $$;
REVOKE ALL ON FUNCTION public.nguon_mon_nam(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.nguon_mon_nam(integer) TO app_runtime;

CREATE FUNCTION public.thong_ke_nam_hoc(p_year integer,p_order integer) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE y public.nam_hoc; snapshot public.ban_chot_nam; groups jsonb;
BEGIN
  SELECT * INTO y FROM public.nam_hoc WHERE ma_nam_hoc=p_year;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  SELECT * INTO snapshot FROM public.ban_chot_nam WHERE ma=public.ban_chot_dang_dung(p_year);
  WITH students AS MATERIALIZED (
    SELECT * FROM public.nguon_hoc_sinh_nam(p_year) s WHERE s.thu_tu=p_order
  ), results AS MATERIALIZED (
    SELECT s.ma_lop,s.ten_lop,s.khoi,m.ma_hoc_sinh,m.ma_mon,m.ten_mon,m.danh_gia_dat,m.diem_tong_ket,m.xep_loai
    FROM public.nguon_mon_nam(p_year) m JOIN students s USING(ma_hoc_ky,ma_hoc_sinh)
  ), by_student AS (
    SELECT v.dim,v.key,v.label,v.sort,count(DISTINCT s.ma_hoc_sinh)::integer AS students,
      jsonb_build_object(
        'TOT',count(*) FILTER(WHERE s.muc_hoc_tap='TOT'),
        'KHA',count(*) FILTER(WHERE s.muc_hoc_tap='KHA'),
        'DAT',count(*) FILTER(WHERE s.muc_hoc_tap='DAT'),
        'CHUA_DAT',count(*) FILTER(WHERE s.muc_hoc_tap='CHUA_DAT'),
        'CHUA_DU_MON',count(*) FILTER(WHERE s.muc_hoc_tap IS NULL)) AS levels
    FROM students s CROSS JOIN LATERAL (VALUES
      ('total',0,'Toàn trường',''),
      ('grade',s.khoi::integer,'Khối '||s.khoi,lpad(s.khoi::text,3,'0')),
      ('class',s.ma_lop,s.ten_lop::text,lpad(s.khoi::text,3,'0')||s.ten_lop)) AS v(dim,key,label,sort)
    GROUP BY v.dim,v.key,v.label,v.sort
  ), by_result AS (
    SELECT v.dim,v.key,v.label,v.sort,count(DISTINCT r.ma_hoc_sinh)::integer AS students,
      jsonb_build_object(
        'average',round(avg(r.diem_tong_ket) FILTER(WHERE NOT r.danh_gia_dat),2)::text,
        'fromEight',count(*) FILTER(WHERE NOT r.danh_gia_dat AND r.diem_tong_ket>=8.0),
        'fromSixHalf',count(*) FILTER(WHERE NOT r.danh_gia_dat AND r.diem_tong_ket>=6.5 AND r.diem_tong_ket<8.0),
        'fromFive',count(*) FILTER(WHERE NOT r.danh_gia_dat AND r.diem_tong_ket>=5.0 AND r.diem_tong_ket<6.5),
        'belowFive',count(*) FILTER(WHERE NOT r.danh_gia_dat AND r.diem_tong_ket<5.0),
        'passed',count(*) FILTER(WHERE r.danh_gia_dat AND r.xep_loai='DAT'),
        'failed',count(*) FILTER(WHERE r.danh_gia_dat AND r.xep_loai='CHUA_DAT'),
        'missing',count(*) FILTER(WHERE r.diem_tong_ket IS NULL)) AS scores
    FROM results r CROSS JOIN LATERAL (VALUES
      ('total',0,'Toàn trường',''),
      ('grade',r.khoi::integer,'Khối '||r.khoi,lpad(r.khoi::text,3,'0')),
      ('class',r.ma_lop,r.ten_lop::text,lpad(r.khoi::text,3,'0')||r.ten_lop),
      ('subject',r.ma_mon,r.ten_mon::text,r.ten_mon::text)) AS v(dim,key,label,sort)
    GROUP BY v.dim,v.key,v.label,v.sort
  ), merged AS (
    SELECT coalesce(a.dim,b.dim) AS dim,coalesce(a.sort,b.sort) AS sort,
      jsonb_build_object('key',coalesce(a.key,b.key),'label',coalesce(a.label,b.label),
        'students',coalesce(a.students,b.students),'levels',a.levels,
        'average',NULL,'fromEight',0,'fromSixHalf',0,'fromFive',0,'belowFive',0,'passed',0,'failed',0,'missing',0)
      ||coalesce(b.scores,'{}'::jsonb) AS item
    FROM by_student a FULL JOIN by_result b ON a.dim=b.dim AND a.key=b.key
  )
  SELECT coalesce(jsonb_object_agg(g.dim,g.items),'{}'::jsonb) INTO groups
  FROM (SELECT dim,jsonb_agg(item ORDER BY sort) AS items FROM merged GROUP BY dim) g;
  RETURN jsonb_build_object('yearId',y.ma_nam_hoc,'yearName',y.ten,
    'source',CASE WHEN snapshot.ma IS NULL THEN 'HIEN_TAI' ELSE 'BAN_CHOT' END,
    'snapshotVersion',snapshot.phien_ban,
    'snapshotAt',to_char(snapshot.thoi_diem AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'schoolName',coalesce(snapshot.ten_truong,(SELECT t.ten_truong FROM public.truong t WHERE t.ma_truong=1)),
    'total',groups->'total'->0,
    'grades',coalesce(groups->'grade','[]'::jsonb),
    'classes',coalesce(groups->'class','[]'::jsonb),
    'subjects',coalesce(groups->'subject','[]'::jsonb));
END $$;
REVOKE ALL ON FUNCTION public.thong_ke_nam_hoc(integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.thong_ke_nam_hoc(integer,integer) TO app_runtime;

CREATE FUNCTION public.so_sanh_nam_hoc(p_order integer) RETURNS jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT coalesce(jsonb_agg((x.result->'total')||jsonb_build_object('yearId',n.ma_nam_hoc,'yearName',x.result->>'yearName',
    'source',x.result->>'source') ORDER BY n.ngay_bat_dau,n.ma_nam_hoc),'[]'::jsonb)
  FROM public.nam_hoc n
  CROSS JOIN LATERAL (SELECT public.thong_ke_nam_hoc(n.ma_nam_hoc,p_order) AS result) x
  WHERE EXISTS(SELECT 1 FROM public.hoc_ky h WHERE h.ma_nam_hoc=n.ma_nam_hoc AND h.thu_tu=p_order AND h.da_cong_bo)
    AND jsonb_typeof(x.result->'total')='object'
$$;
REVOKE ALL ON FUNCTION public.so_sanh_nam_hoc(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.so_sanh_nam_hoc(integer) TO app_runtime;

CREATE OR REPLACE FUNCTION public.doi_trang_thai_nam_hoc(p_phien text,p_year integer,p_close boolean,p_reason text)
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
    PERFORM public.lap_ban_chot_nam(p_year,actor_id);
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

CREATE OR REPLACE FUNCTION public.xoa_hoc_sinh(p_phien text,p_student integer,p_reason text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; why text; st public.hoc_sinh; has_data boolean; outcome text;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  why:=btrim(coalesce(p_reason,''));
  IF p_student IS NULL OR length(why) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'INVALID_REMOVAL_REQUEST' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO st FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF st.da_xoa_luc IS NOT NULL THEN
    RAISE EXCEPTION 'STUDENT_ALREADY_REMOVED' USING ERRCODE='23514'; END IF;

  has_data:=
    EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_hoc_sinh=p_student
      AND (d.gia_tri IS NOT NULL OR d.trang_thai<>'CHUA_CO'
        OR EXISTS(SELECT 1 FROM public.lich_su_sua_diem h WHERE h.ma_diem=d.ma_diem)
        OR EXISTS(SELECT 1 FROM public.lich_su_mien_diem m WHERE m.ma_diem=d.ma_diem)
        OR EXISTS(SELECT 1 FROM public.dong_dieu_chinh a WHERE a.ma_diem=d.ma_diem)))
    OR EXISTS(SELECT 1 FROM public.ket_qua_tong_ket WHERE ma_hoc_sinh=p_student)
    OR EXISTS(SELECT 1 FROM public.ket_qua_dong WHERE ma_hoc_sinh=p_student)
    OR EXISTS(SELECT 1 FROM public.danh_sach_phieu WHERE ma_hoc_sinh=p_student);

  PERFORM set_config('qld.student_removal',p_student::text,true);
  UPDATE public.ban_chot_hoc_sinh SET ho_ten='Học sinh đã xóa #'||p_student,ngay_sinh=DATE '1900-01-01'
  WHERE ma_hoc_sinh=p_student;
  IF has_data THEN
    UPDATE public.hoc_sinh_lop SET trang_thai='NGHI_HOC',
      den_ngay=greatest(CURRENT_DATE,tu_ngay),ly_do=why,nguoi_thuc_hien=actor_id
    WHERE ma_hoc_sinh=p_student AND trang_thai='DANG_HOC';
    UPDATE public.danh_sach_phieu SET ho_ten='Học sinh đã xóa #'||p_student
    WHERE ma_hoc_sinh=p_student;
    UPDATE public.ket_qua_dong SET ho_ten_doc_duoc=NULL
    WHERE ma_hoc_sinh=p_student AND ho_ten_doc_duoc IS NOT NULL;
    UPDATE public.hoc_sinh SET ho_ten='Học sinh đã xóa #'||p_student,
      ngay_sinh=DATE '1900-01-01',ma_nguoi_dung=NULL,da_xoa_luc=now(),dang_theo_hoc=false
    WHERE ma_hoc_sinh=p_student;
    outcome:='ANONYMIZED';
  ELSE
    DELETE FROM public.diem_thanh_phan WHERE ma_hoc_sinh=p_student;
    DELETE FROM public.hoc_sinh_lop WHERE ma_hoc_sinh=p_student;
    DELETE FROM public.hoc_sinh WHERE ma_hoc_sinh=p_student;
    outcome:='DELETED';
  END IF;
  PERFORM set_config('qld.student_removal','',true);

  IF st.ma_nguoi_dung IS NOT NULL THEN
    DELETE FROM public.phien_lam_viec WHERE ma_nguoi_dung=st.ma_nguoi_dung;
    DELETE FROM public.phien_ghi_nho WHERE ma_nguoi_dung=st.ma_nguoi_dung;
    UPDATE public.nguoi_dung SET ten_dang_nhap='da_xoa_'||ma_nguoi_dung,
      mat_khau_ma_hoa='removed',trang_thai=false WHERE ma_nguoi_dung=st.ma_nguoi_dung;
  END IF;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
  VALUES(actor_id,'STUDENT_'||outcome,'hoc_sinh:'||p_student);
  RETURN jsonb_build_object('mode',outcome);
END $$;

-- Năm đã đóng trước migration này được lập bản chốt đầu tiên.
DO $$
DECLARE y record;
BEGIN
  FOR y IN SELECT n.ma_nam_hoc,(SELECT h.nguoi_thuc_hien FROM public.lich_su_dong_nam h
      WHERE h.ma_nam_hoc=n.ma_nam_hoc AND h.hanh_dong='DONG' ORDER BY h.ma DESC LIMIT 1) AS actor
    FROM public.nam_hoc n WHERE n.da_dong_luc IS NOT NULL LOOP
    IF y.actor IS NOT NULL THEN PERFORM public.lap_ban_chot_nam(y.ma_nam_hoc,y.actor); END IF;
  END LOOP;
END $$;

COMMIT;
