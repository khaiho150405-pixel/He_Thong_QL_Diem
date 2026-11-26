-- Quyết định chủ dự án 26/11/2026 (ADR-0021):
-- 1. Học sinh vào lớp sau: tự có ô điểm; hết hạn không bị ghi 0 ở cột đã chấm trước khi em vào lớp.
-- 2. Đánh giá theo Thông tư 22/2021/TT-BGDĐT: môn có điểm chỉ lưu điểm trung bình; môn nhận xét Đạt khi mọi lần
--    đều Đạt; mức kết quả học tập học kỳ tính trên tất cả các môn.
-- Rollback: khôi phục bản trước của xu_ly_han_nhap_diem, tinh_ket_qua_bang_diem, kiem_ma_xep_loai, gỡ trigger
-- enrollment_grid và các hàm mới. Kết quả đã tính giữ nguyên snapshot nên không cần sửa dữ liệu.
BEGIN;

ALTER TABLE public.lich_su_tong_ket ALTER COLUMN xep_loai_moi DROP NOT NULL;

CREATE OR REPLACE FUNCTION public.kiem_ma_xep_loai() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  IF NEW.xep_loai IS NOT NULL AND NEW.xep_loai NOT IN ('DAT','CHUA_DAT') AND NOT EXISTS (
    SELECT 1 FROM public.tieu_chi_xep_loai c WHERE c.ma_xep_loai=NEW.xep_loai
  ) THEN
    RAISE EXCEPTION 'UNKNOWN_CLASSIFICATION' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;

-- "Vào lớp sau", đúng khi gặp một trong ba dấu hiệu:
--   1. ghi danh được tạo sau khi cột mở nhập, trong khi lớp đã có học sinh khác từ trước lúc mở (nhập cả danh sách
--      lớp sau khi đặt lịch không bị coi là vào sau);
--   2. ngày vào lớp sau ngày cột mở nhập;
--   3. bạn cùng lớp đã có điểm ở cột đó trước khi em được ghi danh.
-- Giáo viên bổ sung điểm chuyển đến, điểm kiểm tra bù hoặc miễn bằng đơn điều chỉnh.
CREATE FUNCTION public.hoc_sinh_vao_sau(p_book integer,p_component integer,p_student integer,p_open timestamptz)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT EXISTS(
    SELECT 1 FROM public.bang_diem b
    JOIN public.hoc_sinh_lop g ON g.ma_lop=b.ma_lop AND g.ma_hoc_sinh=p_student AND g.trang_thai='DANG_HOC'
    WHERE b.ma_bang_diem=p_book AND (
      (g.tao_luc > p_open AND EXISTS(SELECT 1 FROM public.hoc_sinh_lop o
        WHERE o.ma_lop=g.ma_lop AND o.ma_hoc_sinh<>g.ma_hoc_sinh AND o.tao_luc <= p_open))
      OR g.tu_ngay > (p_open AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
      OR EXISTS(SELECT 1 FROM public.diem_thanh_phan d JOIN public.lich_su_sua_diem h ON h.ma_diem=d.ma_diem
        WHERE d.ma_bang_diem=b.ma_bang_diem AND d.ma_thanh_phan=p_component AND d.ma_hoc_sinh<>p_student
          AND h.thoi_diem < g.tao_luc)))
$$;
REVOKE ALL ON FUNCTION public.hoc_sinh_vao_sau(integer,integer,integer,timestamptz) FROM PUBLIC;

CREATE FUNCTION public.tao_o_diem_khi_ghi_danh() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b record; n integer;
BEGIN
  IF NEW.trang_thai<>'DANG_HOC' THEN RETURN NULL; END IF;
  FOR b IN SELECT bd.ma_bang_diem,bd.ma_mon FROM public.bang_diem bd JOIN public.hoc_ky k USING(ma_hoc_ky)
    WHERE bd.ma_lop=NEW.ma_lop AND bd.trang_thai='DANG_NHAP_LIEU' AND NOT k.da_cong_bo
      AND k.ngay_ket_thuc>=NEW.tu_ngay ORDER BY bd.ma_bang_diem LOOP
    INSERT INTO public.diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan)
    SELECT b.ma_bang_diem,NEW.ma_hoc_sinh,t.ma_thanh_phan FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon
    ON CONFLICT(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) DO NOTHING;
    GET DIAGNOSTICS n=ROW_COUNT;
    IF n>0 THEN
      UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=b.ma_bang_diem;
      INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
      VALUES(NEW.nguoi_thuc_hien,'GRADEBOOK_STUDENT_AUTO_ADDED',b.ma_bang_diem::text||':'||NEW.ma_hoc_sinh::text);
    END IF;
  END LOOP;
  RETURN NULL;
END $$;
CREATE TRIGGER enrollment_grid AFTER INSERT OR UPDATE OF trang_thai ON public.hoc_sinh_lop
  FOR EACH ROW EXECUTE FUNCTION public.tao_o_diem_khi_ghi_danh();

-- Thông tư 22/2021/TT-BGDĐT, Điều 9 khoản 2: 3 = Tốt, 2 = Khá, 1 = Đạt, 0 = Chưa đạt.
CREATE FUNCTION public.muc_ket_qua_tt22(p_scores numeric[],p_failed integer) RETURNS integer
LANGUAGE sql IMMUTABLE SET search_path=pg_catalog AS $$
  SELECT CASE
    WHEN p_failed=0 AND bool_and(s>=6.5) AND count(*) FILTER(WHERE s>=8.0)>=6 THEN 3
    WHEN p_failed=0 AND bool_and(s>=5.0) AND count(*) FILTER(WHERE s>=6.5)>=6 THEN 2
    WHEN p_failed<=1 AND bool_and(s>=3.5) AND count(*) FILTER(WHERE s>=5.0)>=6 THEN 1
    ELSE 0 END
  FROM unnest(p_scores) AS s
$$;

-- Điều 9 khoản 3: nếu chỉ do một môn mà mức bị thấp đi từ 02 mức trở lên thì nâng lên mức liền kề.
CREATE FUNCTION public.xep_muc_hoc_tap(p_student integer,p_term integer) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE scores numeric[]; failed integer; graded integer; base integer; best integer; i integer; alt numeric[];
BEGIN
  SELECT coalesce(array_agg(k.diem_tong_ket ORDER BY k.ma_mon) FILTER(WHERE NOT m.danh_gia_dat),'{}'),
         count(*) FILTER(WHERE m.danh_gia_dat AND k.diem_tong_ket<10.0),
         count(*) FILTER(WHERE m.danh_gia_dat)
  INTO scores,failed,graded
  FROM public.ket_qua_tong_ket k JOIN public.mon_hoc m USING(ma_mon)
  WHERE k.ma_hoc_sinh=p_student AND k.ma_hoc_ky=p_term;
  IF cardinality(scores)<6 THEN
    RETURN jsonb_build_object('level',NULL,'numericSubjects',cardinality(scores),'passFailSubjects',graded,'raised',false);
  END IF;
  base:=public.muc_ket_qua_tt22(scores,failed);
  best:=base;
  FOR i IN 1..cardinality(scores) LOOP
    alt:=scores; alt[i]:=10.0;
    best:=greatest(best,public.muc_ket_qua_tt22(alt,failed));
  END LOOP;
  IF failed>0 THEN best:=greatest(best,public.muc_ket_qua_tt22(scores,failed-1)); END IF;
  IF best>=base+2 THEN
    RETURN jsonb_build_object('level',(ARRAY['CHUA_DAT','DAT','KHA','TOT'])[base+2],
      'numericSubjects',cardinality(scores),'passFailSubjects',graded,'raised',true);
  END IF;
  RETURN jsonb_build_object('level',(ARRAY['CHUA_DAT','DAT','KHA','TOT'])[base+1],
    'numericSubjects',cardinality(scores),'passFailSubjects',graded,'raised',false);
END $$;
REVOKE ALL ON FUNCTION public.xep_muc_hoc_tap(integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.xep_muc_hoc_tap(integer,integer) TO app_runtime;

CREATE OR REPLACE FUNCTION public.xu_ly_han_nhap_diem()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE w record; b public.bang_diem; d public.diem_thanh_phan; n integer:=0;
BEGIN
 IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
 IF NOT pg_try_advisory_xact_lock(714042026) THEN RETURN 0; END IF;
 FOR w IN SELECT bd.ma_bang_diem,t.ma_thanh_phan,t.bat_buoc,e.nguoi_dat,e.mo_luc
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
 WHERE g.ma_bang_diem=b.ma_bang_diem AND g.ma_thanh_phan=w.ma_thanh_phan AND hs.con_hoc AND g.trang_thai<>'MIEN' AND (g.gia_tri IS NULL OR g.trang_thai<>'DA_DUYET')
 AND NOT public.hoc_sinh_vao_sau(b.ma_bang_diem,w.ma_thanh_phan,g.ma_hoc_sinh,w.mo_luc) FOR UPDATE OF g LOOP
 UPDATE public.diem_thanh_phan SET gia_tri=0.0,trang_thai='DA_DUYET',nguon_nhap='NHAP_TAY' WHERE ma_diem=d.ma_diem;
 INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
 VALUES(d.ma_diem,w.nguoi_dat,d.gia_tri,0.0,'Hệ thống tự ghi 0 do hết hạn nhập điểm do nhà trường đặt; ô thiếu hoặc chưa được duyệt.');
 END LOOP;
 END IF;
 IF w.bat_buoc THEN
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
 SELECT NULL,'GRADE_LATE_STUDENT_PENDING',b.ma_bang_diem::text||':'||w.ma_thanh_phan::text||':'||g.ma_hoc_sinh::text
 FROM public.diem_thanh_phan g JOIN public.hoc_sinh_cua_lop(b.ma_lop,b.ma_hoc_ky) hs USING(ma_hoc_sinh)
 WHERE g.ma_bang_diem=b.ma_bang_diem AND g.ma_thanh_phan=w.ma_thanh_phan AND hs.con_hoc AND g.trang_thai<>'MIEN'
 AND (g.gia_tri IS NULL OR g.trang_thai<>'DA_DUYET');
 END IF;
 UPDATE public.phieu_nhan_dien SET trang_thai='LOI',ma_loi='GRADE_DEADLINE_EXPIRED',version=version+1 WHERE ma_bang_diem=b.ma_bang_diem AND ma_thanh_phan=w.ma_thanh_phan AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU');
 INSERT INTO public.chot_cot_diem(ma_bang_diem,ma_thanh_phan,nguoi_chot) VALUES(b.ma_bang_diem,w.ma_thanh_phan,w.nguoi_dat);
 UPDATE public.bang_diem SET version=version+1,trang_thai=CASE WHEN NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)) THEN 'DA_CHOT'::public."TrangThaiBangDiem" ELSE trang_thai END WHERE ma_bang_diem=b.ma_bang_diem;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(NULL,'GRADE_COLUMN_AUTO_LOCKED',b.ma_bang_diem::text||':'||w.ma_thanh_phan::text);
 n:=n+1;
 END LOOP;
 RETURN n;
END $function$;

CREATE OR REPLACE FUNCTION public.tinh_ket_qua_bang_diem(p_phien text, p_book integer, p_version integer, p_reason text, p_idempotency_key text, p_request_hash text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
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
  IF b.trang_thai<>'DA_CHOT' THEN
    RAISE EXCEPTION 'GRADEBOOK_NOT_LOCKED' USING ERRCODE='23514';
  END IF;
  IF b.version<>p_version THEN
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
  IF NOT FOUND THEN
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
  full_snapshot:=jsonb_build_object('standard','TT22/2021/TT-BGDDT','weights',weight_snapshot,'classificationPolicy',policy_snapshot,'assessmentMode',CASE WHEN pass_fail THEN 'PASS_FAIL' ELSE 'NUMERIC' END);

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
    classification:=NULL;
    IF pass_fail THEN
      IF EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=p_book
          AND d.ma_hoc_sinh=student.ma_hoc_sinh AND d.trang_thai='DA_DUYET' AND d.gia_tri<10.0) THEN
        rounded:=0.0; classification:='CHUA_DAT';
      ELSE rounded:=10.0; classification:='DAT'; END IF;
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
END $function$;

COMMIT;
