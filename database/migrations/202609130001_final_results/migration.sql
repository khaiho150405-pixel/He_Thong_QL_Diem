-- UC14-15: versioned calculation policy, coefficient snapshot and append-only recalculation history.
BEGIN;

CREATE TABLE public.chinh_sach_xep_loai (
  ma_chinh_sach SERIAL PRIMARY KEY,
  phien_ban VARCHAR(20) NOT NULL UNIQUE,
  ten VARCHAR(100) NOT NULL,
  so_chu_so_lam_tron SMALLINT NOT NULL DEFAULT 1,
  dang_ap_dung BOOLEAN NOT NULL DEFAULT false,
  ngay_tao TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT chinh_sach_phien_ban_not_blank CHECK (length(btrim(phien_ban)) BETWEEN 1 AND 20),
  CONSTRAINT chinh_sach_ten_not_blank CHECK (length(btrim(ten)) BETWEEN 1 AND 100),
  CONSTRAINT chinh_sach_rounding_supported CHECK (so_chu_so_lam_tron BETWEEN 0 AND 1)
);
CREATE UNIQUE INDEX chinh_sach_xep_loai_active_unique
  ON public.chinh_sach_xep_loai (dang_ap_dung) WHERE dang_ap_dung;

CREATE TABLE public.tieu_chi_xep_loai (
  ma_tieu_chi SERIAL PRIMARY KEY,
  ma_chinh_sach INTEGER NOT NULL REFERENCES public.chinh_sach_xep_loai(ma_chinh_sach) ON DELETE RESTRICT,
  ma_xep_loai VARCHAR(20) NOT NULL,
  diem_toi_thieu NUMERIC(3,1) NOT NULL,
  thu_tu SMALLINT NOT NULL,
  CONSTRAINT tieu_chi_ma_not_blank CHECK (length(btrim(ma_xep_loai)) BETWEEN 1 AND 20),
  CONSTRAINT tieu_chi_diem_range CHECK (diem_toi_thieu BETWEEN 0.0 AND 10.0),
  CONSTRAINT tieu_chi_diem_step CHECK (diem_toi_thieu * 10 = trunc(diem_toi_thieu * 10)),
  CONSTRAINT tieu_chi_thu_tu_positive CHECK (thu_tu > 0),
  UNIQUE (ma_chinh_sach, ma_xep_loai),
  UNIQUE (ma_chinh_sach, diem_toi_thieu),
  UNIQUE (ma_chinh_sach, thu_tu)
);

-- Development default only. Production thresholds remain a school policy decision.
INSERT INTO public.chinh_sach_xep_loai(phien_ban,ten,so_chu_so_lam_tron,dang_ap_dung)
VALUES ('DEV-2026-01','Mặc định development - cần nhà trường xác nhận',1,true);
INSERT INTO public.tieu_chi_xep_loai(ma_chinh_sach,ma_xep_loai,diem_toi_thieu,thu_tu)
SELECT p.ma_chinh_sach,c.ma_xep_loai,c.diem_toi_thieu,c.thu_tu
FROM public.chinh_sach_xep_loai p
CROSS JOIN (VALUES
  ('GIOI'::varchar,8.0::numeric,1::smallint),
  ('KHA'::varchar,6.5::numeric,2::smallint),
  ('TRUNG_BINH'::varchar,5.0::numeric,3::smallint),
  ('YEU'::varchar,0.0::numeric,4::smallint)
) AS c(ma_xep_loai,diem_toi_thieu,thu_tu)
WHERE p.phien_ban='DEV-2026-01';

CREATE TABLE public.lich_su_tong_ket (
  ma_lich_su BIGSERIAL PRIMARY KEY,
  ma_ket_qua BIGINT NOT NULL REFERENCES public.ket_qua_tong_ket(ma_ket_qua) ON DELETE RESTRICT,
  nguoi_tinh INTEGER NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT,
  diem_cu NUMERIC(3,1),
  xep_loai_cu VARCHAR(20),
  bo_he_so_cu JSONB,
  diem_moi NUMERIC(3,1) NOT NULL,
  xep_loai_moi VARCHAR(20) NOT NULL,
  bo_he_so_moi JSONB NOT NULL,
  ly_do VARCHAR(500) NOT NULL,
  thoi_diem TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT lich_su_tong_ket_diem_cu CHECK (diem_cu IS NULL OR diem_cu BETWEEN 0.0 AND 10.0),
  CONSTRAINT lich_su_tong_ket_diem_moi CHECK (diem_moi BETWEEN 0.0 AND 10.0),
  CONSTRAINT lich_su_tong_ket_reason CHECK (length(btrim(ly_do)) BETWEEN 1 AND 500)
);
CREATE INDEX lich_su_tong_ket_ket_qua_idx ON public.lich_su_tong_ket(ma_ket_qua,ma_lich_su);
CREATE INDEX lich_su_tong_ket_nguoi_tinh_idx ON public.lich_su_tong_ket(nguoi_tinh);

CREATE FUNCTION public.chan_sua_lich_su_tong_ket() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  RAISE EXCEPTION 'APPEND_ONLY' USING ERRCODE='42501';
END $$;
CREATE TRIGGER lich_su_tong_ket_append_only
BEFORE UPDATE OR DELETE OR TRUNCATE ON public.lich_su_tong_ket
FOR EACH STATEMENT EXECUTE FUNCTION public.chan_sua_lich_su_tong_ket();

CREATE FUNCTION public.tinh_ket_qua_bang_diem(
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
           'coefficient',tp.he_so::text,'required',tp.bat_buoc)
           ORDER BY tp.thu_tu_hien_thi,tp.ma_thanh_phan),'[]'::jsonb),
         ('W-'||substr(md5(string_agg(tp.ma_thanh_phan::text||':'||tp.he_so::text||':'||tp.bat_buoc::text,
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

    SELECT sum(d.gia_tri*tp.he_so),sum(tp.he_so)
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

GRANT SELECT ON public.chinh_sach_xep_loai,public.tieu_chi_xep_loai,public.lich_su_tong_ket TO app_runtime;
REVOKE UPDATE,DELETE,TRUNCATE ON public.lich_su_tong_ket FROM app_runtime;
REVOKE ALL ON FUNCTION public.tinh_ket_qua_bang_diem(text,integer,integer,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tinh_ket_qua_bang_diem(text,integer,integer,text,text,text) TO app_runtime;

-- Forward-only rollback: revoke function execution and deactivate the policy in a later migration.
-- Final results and their append-only history must be retained for auditability.
COMMIT;
