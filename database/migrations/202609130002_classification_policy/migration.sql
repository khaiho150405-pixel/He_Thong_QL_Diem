-- UC15-16: administrator-managed policy versions and explicit pass/fail semantics.
BEGIN;
ALTER TABLE public.tieu_chi_xep_loai ADD COLUMN dat BOOLEAN NOT NULL DEFAULT false;
UPDATE public.tieu_chi_xep_loai SET dat=true WHERE ma_xep_loai IN ('GIOI','KHA','TRUNG_BINH');

CREATE FUNCTION public.kich_hoat_chinh_sach_xep_loai(
  p_phien text,p_version text,p_name text,p_rounding smallint,p_criteria jsonb,
  p_idempotency_key text,p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; policy_id integer; item jsonb; prior public.khoa_idempotency;
 code text; minimum numeric; ordering integer; passing boolean; result jsonb;
BEGIN
 IF current_setting('transaction_isolation')<>'serializable' THEN
   RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
 IF length(btrim(p_version)) NOT BETWEEN 1 AND 20 OR p_version !~ '^[A-Za-z0-9._-]+$'
 OR length(btrim(p_name)) NOT BETWEEN 1 AND 100 OR p_rounding NOT BETWEEN 0 AND 1
 OR jsonb_typeof(p_criteria)<>'array' OR jsonb_array_length(p_criteria) NOT BETWEEN 2 AND 20
 OR length(p_idempotency_key) NOT BETWEEN 1 AND 64 OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$'
 OR p_request_hash !~ '^[0-9a-f]{64}$' THEN
   RAISE EXCEPTION 'INVALID_CLASSIFICATION_POLICY' USING ERRCODE='23514'; END IF;
 SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s
 JOIN public.nguoi_dung u USING(ma_nguoi_dung)
 WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN'
 AND s.het_han>statement_timestamp() AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
 IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
 SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id
 AND thao_tac='CLASS_POLICY' AND khoa=p_idempotency_key;
 IF FOUND THEN
   IF prior.ma_bam_yeu_cau<>p_request_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
   RETURN prior.ket_qua;
 END IF;
 UPDATE public.chinh_sach_xep_loai SET dang_ap_dung=false WHERE dang_ap_dung;
 INSERT INTO public.chinh_sach_xep_loai(phien_ban,ten,so_chu_so_lam_tron,dang_ap_dung)
 VALUES(btrim(p_version),btrim(p_name),p_rounding,true) RETURNING ma_chinh_sach INTO policy_id;
 FOR item IN SELECT value FROM jsonb_array_elements(p_criteria) LOOP
   IF jsonb_typeof(item)<>'object' OR NOT (item ?& ARRAY['code','minimum','passing','order'])
   OR (item-ARRAY['code','minimum','passing','order'])<>'{}'::jsonb
   OR jsonb_typeof(item->'code')<>'string' OR jsonb_typeof(item->'minimum')<>'string'
   OR jsonb_typeof(item->'passing')<>'boolean' OR jsonb_typeof(item->'order')<>'number'
   OR (item->>'code') !~ '^[A-Z][A-Z0-9_]{0,19}$'
   OR (item->>'minimum') !~ '^(10[.]0|[0-9][.][0-9])$'
   OR (item->>'order') !~ '^[1-9][0-9]{0,3}$' THEN
     RAISE EXCEPTION 'INVALID_CLASSIFICATION_CRITERION' USING ERRCODE='23514'; END IF;
   code:=item->>'code'; minimum:=(item->>'minimum')::numeric;
   passing:=(item->>'passing')::boolean; ordering:=(item->>'order')::integer;
   INSERT INTO public.tieu_chi_xep_loai(ma_chinh_sach,ma_xep_loai,diem_toi_thieu,thu_tu,dat)
   VALUES(policy_id,code,minimum,ordering,passing);
 END LOOP;
 IF NOT EXISTS(SELECT 1 FROM public.tieu_chi_xep_loai WHERE ma_chinh_sach=policy_id AND diem_toi_thieu=0.0)
 OR NOT EXISTS(SELECT 1 FROM public.tieu_chi_xep_loai WHERE ma_chinh_sach=policy_id AND dat)
 OR NOT EXISTS(SELECT 1 FROM public.tieu_chi_xep_loai WHERE ma_chinh_sach=policy_id AND NOT dat) THEN
   RAISE EXCEPTION 'CLASSIFICATION_POLICY_INCOMPLETE' USING ERRCODE='23514'; END IF;
 SELECT jsonb_build_object('version',p.phien_ban,'name',p.ten,'roundingDigits',p.so_chu_so_lam_tron,
 'active',p.dang_ap_dung,'criteria',jsonb_agg(jsonb_build_object('code',c.ma_xep_loai,
 'minimum',c.diem_toi_thieu::text,'passing',c.dat,'order',c.thu_tu) ORDER BY c.diem_toi_thieu DESC))
 INTO result FROM public.chinh_sach_xep_loai p JOIN public.tieu_chi_xep_loai c USING(ma_chinh_sach)
 WHERE p.ma_chinh_sach=policy_id GROUP BY p.ma_chinh_sach;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
 VALUES(actor_id,'CLASSIFICATION_POLICY_ACTIVATED','chinh_sach_xep_loai:'||p_version);
 INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua)
 VALUES(p_idempotency_key,actor_id,'CLASS_POLICY',p_request_hash,result);
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.kich_hoat_chinh_sach_xep_loai(text,text,text,smallint,jsonb,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.kich_hoat_chinh_sach_xep_loai(text,text,text,smallint,jsonb,text,text) TO app_runtime;
-- Forward-only rollback: activate a reviewed replacement policy; preserve used versions.
COMMIT;
