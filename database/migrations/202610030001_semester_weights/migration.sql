BEGIN;
CREATE TABLE public.he_so_hoc_ky (
 ma_he_so SERIAL PRIMARY KEY,
 ma_thanh_phan INTEGER NOT NULL REFERENCES public.thanh_phan_diem(ma_thanh_phan) ON DELETE RESTRICT,
 ma_hoc_ky INTEGER NOT NULL REFERENCES public.hoc_ky(ma_hoc_ky) ON DELETE RESTRICT,
 he_so NUMERIC(3,2) NOT NULL CHECK (he_so > 0 AND he_so <= 9.99),
 UNIQUE(ma_thanh_phan,ma_hoc_ky)
);
CREATE INDEX he_so_hoc_ky_ma_hoc_ky_idx ON public.he_so_hoc_ky(ma_hoc_ky);
GRANT SELECT,INSERT,UPDATE,DELETE ON public.he_so_hoc_ky TO app_runtime;
GRANT USAGE,SELECT ON SEQUENCE public.he_so_hoc_ky_ma_he_so_seq TO app_runtime;

CREATE FUNCTION public.he_so_ap_dung(p_component integer,p_term integer) RETURNS numeric
LANGUAGE sql STABLE SET search_path=pg_catalog,public AS $$
 SELECT coalesce(h.he_so,t.he_so) FROM public.thanh_phan_diem t
 LEFT JOIN public.he_so_hoc_ky h ON h.ma_thanh_phan=t.ma_thanh_phan AND h.ma_hoc_ky=p_term
 WHERE t.ma_thanh_phan=p_component
$$;
REVOKE ALL ON FUNCTION public.he_so_ap_dung(integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.he_so_ap_dung(integer,integer) TO app_runtime;

CREATE FUNCTION public.kiem_tra_he_so_hoc_ky() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,public AS $$
DECLARE row_data record; locked record;
BEGIN
 FOR row_data IN SELECT * FROM (VALUES
   (CASE WHEN TG_OP <> 'DELETE' THEN NEW.ma_thanh_phan ELSE NULL END, CASE WHEN TG_OP <> 'DELETE' THEN NEW.ma_hoc_ky ELSE NULL END),
   (CASE WHEN TG_OP <> 'INSERT' THEN OLD.ma_thanh_phan ELSE NULL END, CASE WHEN TG_OP <> 'INSERT' THEN OLD.ma_hoc_ky ELSE NULL END)
 ) AS v(component_id,term_id) LOOP
   FOR locked IN SELECT b.trang_thai FROM public.bang_diem b JOIN public.thanh_phan_diem t ON t.ma_mon=b.ma_mon
     WHERE t.ma_thanh_phan=row_data.component_id AND b.ma_hoc_ky=row_data.term_id
     ORDER BY b.ma_bang_diem FOR UPDATE OF b LOOP
     IF locked.trang_thai='DA_CHOT' THEN
       RAISE EXCEPTION 'SEMESTER_WEIGHTS_LOCKED' USING ERRCODE='23514';
     END IF;
   END LOOP;
 END LOOP;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER semester_weights_locked BEFORE INSERT OR UPDATE OR DELETE ON public.he_so_hoc_ky
FOR EACH ROW EXECUTE FUNCTION public.kiem_tra_he_so_hoc_ky();

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
  full_snapshot:=jsonb_build_object('weights',weight_snapshot,'classificationPolicy',policy_snapshot);

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
-- Forward-only: preserve configured coefficients and historical snapshots. Revoke writes
-- in a follow-up migration if this feature must be disabled; do not drop used data.
COMMIT;
