BEGIN;
ALTER TABLE public.hoc_ky ADD COLUMN da_cong_bo boolean NOT NULL DEFAULT false;
ALTER TABLE public.mon_hoc ADD COLUMN danh_gia_dat boolean NOT NULL DEFAULT false;
ALTER TABLE public.thanh_phan_diem ADD COLUMN loai_he_so varchar(2) NOT NULL DEFAULT 'TX' CHECK (loai_he_so IN ('TX','GK','CK'));
UPDATE public.thanh_phan_diem SET loai_he_so=CASE WHEN lower(ten_thanh_phan) LIKE '%giữa%' OR lower(ten_thanh_phan) LIKE '%giua%' THEN 'GK' WHEN lower(ten_thanh_phan) LIKE '%cuối%' OR lower(ten_thanh_phan) LIKE '%cuoi%' THEN 'CK' ELSE 'TX' END;
CREATE TABLE public.he_so_hoc_ky_chung (
 ma_he_so serial PRIMARY KEY,
 ma_hoc_ky integer NOT NULL REFERENCES public.hoc_ky ON DELETE RESTRICT,
 loai_he_so varchar(2) NOT NULL CHECK (loai_he_so IN ('TX','GK','CK')),
 he_so numeric(3,2) NOT NULL CHECK (he_so>0 AND he_so<=9.99),
 UNIQUE(ma_hoc_ky,loai_he_so)
);
-- Keep legacy per-subject overrides and historical snapshots untouched for traceability.
INSERT INTO public.he_so_hoc_ky_chung(ma_hoc_ky,loai_he_so,he_so)
SELECT h.ma_hoc_ky,v.loai,v.he_so FROM public.hoc_ky h CROSS JOIN (VALUES ('TX',1.00),('GK',2.00),('CK',3.00)) v(loai,he_so);
GRANT SELECT,INSERT,UPDATE,DELETE ON public.he_so_hoc_ky_chung TO app_runtime;
GRANT USAGE,SELECT ON SEQUENCE public.he_so_hoc_ky_chung_ma_he_so_seq TO app_runtime;
CREATE OR REPLACE FUNCTION public.he_so_ap_dung(p_component integer,p_term integer) RETURNS numeric
LANGUAGE sql STABLE SET search_path=pg_catalog,public AS $$
 SELECT coalesce(h.he_so,CASE t.loai_he_so WHEN 'GK' THEN 2.00 WHEN 'CK' THEN 3.00 ELSE 1.00 END)
 FROM public.thanh_phan_diem t LEFT JOIN public.he_so_hoc_ky_chung h ON h.loai_he_so=t.loai_he_so AND h.ma_hoc_ky=p_term
 WHERE t.ma_thanh_phan=p_component
$$;
CREATE TABLE public.chot_cot_diem (
 ma_bang_diem integer NOT NULL REFERENCES public.bang_diem ON DELETE RESTRICT,
 ma_thanh_phan integer NOT NULL REFERENCES public.thanh_phan_diem ON DELETE RESTRICT,
 nguoi_chot integer REFERENCES public.nguoi_dung ON DELETE RESTRICT,
 thoi_diem timestamptz(6) NOT NULL DEFAULT now(),
 PRIMARY KEY(ma_bang_diem,ma_thanh_phan)
);
GRANT SELECT ON public.chot_cot_diem TO app_runtime;
INSERT INTO public.chot_cot_diem(ma_bang_diem,ma_thanh_phan)
SELECT b.ma_bang_diem,t.ma_thanh_phan FROM public.bang_diem b JOIN public.thanh_phan_diem t USING(ma_mon) WHERE b.trang_thai='DA_CHOT';
CREATE FUNCTION public.chot_cot(p_phien text,p_book integer,p_component integer,p_version integer)
RETURNS SETOF public.bang_diem LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; actor_id integer; required boolean;
BEGIN
 b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
 SELECT ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec WHERE ma_bam=p_phien;
 SELECT bat_buoc INTO required FROM public.thanh_phan_diem WHERE ma_mon=b.ma_mon AND ma_thanh_phan=p_component;
 IF NOT FOUND THEN RAISE EXCEPTION 'COMPONENT_OUTSIDE_BOOK' USING ERRCODE='P0002'; END IF;
 IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component) THEN
 RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM public.phieu_nhan_dien WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) OR
 EXISTS(SELECT 1 FROM public.diem_thanh_phan WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component AND trang_thai='CHO_DOI_CHIEU') THEN
 RAISE EXCEPTION 'PENDING_REVIEW' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM public.hoc_sinh hs LEFT JOIN public.diem_thanh_phan d ON d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.ma_bang_diem=p_book AND d.ma_thanh_phan=p_component
 WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc AND (d.ma_diem IS NULL OR (required AND (d.gia_tri IS NULL OR d.trang_thai<>'DA_DUYET')))) THEN
 RAISE EXCEPTION 'INCOMPLETE_COLUMN' USING ERRCODE='23514'; END IF;
 INSERT INTO public.chot_cot_diem VALUES(p_book,p_component,actor_id,statement_timestamp());
 UPDATE public.bang_diem SET version=version+1,
 trang_thai=CASE WHEN NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=p_book AND c.ma_thanh_phan=t.ma_thanh_phan)) THEN 'DA_CHOT'::public."TrangThaiBangDiem" ELSE trang_thai END
 WHERE ma_bang_diem=p_book;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADE_COLUMN_LOCKED',p_book::text||':'||p_component::text);
 RETURN QUERY SELECT * FROM public.bang_diem WHERE ma_bang_diem=p_book;
END $$;
REVOKE ALL ON FUNCTION public.chot_cot(text,integer,integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.chot_cot(text,integer,integer,integer) TO app_runtime;
CREATE FUNCTION public.kiem_cot_diem() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem;
BEGIN
 SELECT * INTO b FROM public.bang_diem WHERE ma_bang_diem=NEW.ma_bang_diem FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=NEW.ma_bang_diem AND ma_thanh_phan=NEW.ma_thanh_phan) THEN
 RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 IF NEW.gia_tri IS NOT NULL AND EXISTS(SELECT 1 FROM public.mon_hoc WHERE ma_mon=b.ma_mon AND danh_gia_dat) AND NEW.gia_tri NOT IN (0.0,10.0) THEN
 RAISE EXCEPTION 'PASS_FAIL_VALUE_REQUIRED' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER grade_column_policy BEFORE UPDATE ON public.diem_thanh_phan FOR EACH ROW EXECUTE FUNCTION public.kiem_cot_diem();
CREATE FUNCTION public.kiem_phieu_cot() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 PERFORM 1 FROM public.bang_diem WHERE ma_bang_diem=NEW.ma_bang_diem FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=NEW.ma_bang_diem AND ma_thanh_phan=NEW.ma_thanh_phan) THEN
 RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER recognition_column_policy BEFORE INSERT ON public.phieu_nhan_dien FOR EACH ROW EXECUTE FUNCTION public.kiem_phieu_cot();
CREATE FUNCTION public.kiem_he_so_chung() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record;
BEGIN
 FOR r IN SELECT b.trang_thai,b.ma_bang_diem FROM public.bang_diem b WHERE b.ma_hoc_ky IN (CASE WHEN TG_OP<>'DELETE' THEN NEW.ma_hoc_ky END,CASE WHEN TG_OP<>'INSERT' THEN OLD.ma_hoc_ky END) ORDER BY b.ma_bang_diem FOR UPDATE LOOP
 IF r.trang_thai='DA_CHOT' OR EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=r.ma_bang_diem) THEN
 RAISE EXCEPTION 'SEMESTER_WEIGHTS_LOCKED' USING ERRCODE='23514'; END IF;
 END LOOP;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER global_weights_locked BEFORE INSERT OR UPDATE OR DELETE ON public.he_so_hoc_ky_chung FOR EACH ROW EXECUTE FUNCTION public.kiem_he_so_chung();
CREATE FUNCTION public.kiem_cong_bo() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r record;
BEGIN
 IF NEW.da_cong_bo AND NOT OLD.da_cong_bo THEN
 IF NOT EXISTS(SELECT 1 FROM public.bang_diem WHERE ma_hoc_ky=NEW.ma_hoc_ky) THEN RAISE EXCEPTION 'NO_RESULTS_TO_PUBLISH' USING ERRCODE='23514'; END IF;
 FOR r IN SELECT * FROM public.bang_diem WHERE ma_hoc_ky=NEW.ma_hoc_ky ORDER BY ma_bang_diem FOR UPDATE LOOP
 IF r.trang_thai<>'DA_CHOT' OR EXISTS(SELECT 1 FROM public.hoc_sinh hs WHERE hs.ma_lop=r.ma_lop AND hs.dang_theo_hoc AND NOT EXISTS(SELECT 1 FROM public.ket_qua_tong_ket k WHERE k.ma_hoc_sinh=hs.ma_hoc_sinh AND k.ma_mon=r.ma_mon AND k.ma_hoc_ky=r.ma_hoc_ky)) THEN
 RAISE EXCEPTION 'TERM_RESULTS_INCOMPLETE' USING ERRCODE='23514'; END IF;
 END LOOP;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER term_publication BEFORE UPDATE ON public.hoc_ky FOR EACH ROW EXECUTE FUNCTION public.kiem_cong_bo();
CREATE FUNCTION public.kiem_mon_danh_gia() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
BEGIN
 IF NEW.danh_gia_dat IS DISTINCT FROM OLD.danh_gia_dat AND EXISTS(SELECT 1 FROM public.bang_diem WHERE ma_mon=OLD.ma_mon) THEN
 RAISE EXCEPTION 'SUBJECT_MODE_IN_USE' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER subject_mode_policy BEFORE UPDATE ON public.mon_hoc FOR EACH ROW EXECUTE FUNCTION public.kiem_mon_danh_gia();
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
    SELECT coalesce(jsonb_agg(jsonb_build_object('componentId',tp.ma_thanh_phan,'name',tp.ten_thanh_phan)
             ORDER BY tp.thu_tu_hien_thi),'[]'::jsonb)
    INTO missing
    FROM public.thanh_phan_diem tp LEFT JOIN public.diem_thanh_phan d
      ON d.ma_bang_diem=p_book AND d.ma_hoc_sinh=student.ma_hoc_sinh
     AND d.ma_thanh_phan=tp.ma_thanh_phan
    WHERE tp.ma_mon=b.ma_mon AND tp.bat_buoc
      AND (d.ma_diem IS NULL OR d.gia_tri IS NULL OR d.trang_thai<>'DA_DUYET');
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

  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'FINAL_RESULTS_CALCULATED','bang_diem:'||p_book::text);
  result:=jsonb_build_object('gradebookId',p_book,'gradebookVersion',b.version,
    'weightVersion',weight_version,'policyVersion',policy.phien_ban,
    'calculatedStudents',calculated,'skippedStudents',jsonb_array_length(skipped),
    'results',results,'skipped',skipped);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua)
  VALUES(p_idempotency_key,actor_id,'FINAL_RESULTS',p_request_hash,result);
  RETURN result;
END $$;

-- Forward-only: keep historical grades, overrides, snapshots and column locks. Rollback via a reviewed forward migration.
COMMIT;
