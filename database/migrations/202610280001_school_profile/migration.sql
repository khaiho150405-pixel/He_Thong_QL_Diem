-- Thông tin trường (ADR-0019): mức 1 "mỗi trường một bản cài" — bảng truong giới hạn đúng một dòng (ma_truong = 1) nhưng có
-- khóa ma_truong để sau này mở nhiều trường chỉ cần nới CHECK và thêm ma_truong vào các bảng khác. Chỉ QTV sửa, qua hàm SQL;
-- runtime chỉ SELECT. Logo lưu ở kho đối tượng, bảng chỉ giữ key/content-type/checksum.
--
-- ROLLBACK (chỉ tiến): thu hồi EXECUTE của hai hàm bằng migration mới; không DROP bảng truong vì tên trường được UI đọc.
BEGIN;

CREATE TABLE public.truong (
  ma_truong smallint PRIMARY KEY DEFAULT 1 CHECK (ma_truong = 1),
  ten_truong varchar(200) NOT NULL CHECK (length(btrim(ten_truong)) >= 3),
  ten_ngan varchar(60) NOT NULL CHECK (length(btrim(ten_ngan)) >= 2),
  co_quan_chu_quan varchar(200),
  dia_chi varchar(300),
  dien_thoai varchar(20),
  email varchar(200),
  hieu_truong varchar(120),
  logo_key varchar(300),
  logo_content_type varchar(30),
  logo_checksum varchar(64),
  phien_ban integer NOT NULL DEFAULT 1,
  cap_nhat_luc timestamptz NOT NULL DEFAULT now(),
  nguoi_cap_nhat integer REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT,
  CONSTRAINT truong_logo_dong_bo CHECK ((logo_key IS NULL) = (logo_content_type IS NULL) AND (logo_key IS NULL) = (logo_checksum IS NULL))
);

CREATE FUNCTION public.cam_xoa_truong() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN RAISE EXCEPTION 'SCHOOL_PROFILE_PROTECTED' USING ERRCODE='23514'; END $$;
CREATE TRIGGER truong_cam_xoa BEFORE DELETE ON public.truong FOR EACH ROW EXECUTE FUNCTION public.cam_xoa_truong();
CREATE TRIGGER truong_cam_truncate BEFORE TRUNCATE ON public.truong FOR EACH STATEMENT EXECUTE FUNCTION public.cam_xoa_truong();

INSERT INTO public.truong(ma_truong, ten_truong, ten_ngan, co_quan_chu_quan)
VALUES (1, 'Trường THPT Bà Điểm', 'THPT Bà Điểm', 'Sở Giáo dục và Đào tạo TP. Hồ Chí Minh');

GRANT SELECT ON public.truong TO app_runtime;

-- Sửa thông tin văn bản. p_data = {name, shortName, governingBody?, address?, phone?, email?, principal?}; chuỗi rỗng/null → NULL.
CREATE FUNCTION public.cap_nhat_thong_tin_truong(p_phien text,p_expected_version integer,p_data jsonb,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; cur public.truong; prior public.khoa_idempotency; k text; vals jsonb:='{}'; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  IF p_expected_version IS NULL OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$'
     OR p_data IS NULL OR jsonb_typeof(p_data)<>'object' THEN
    RAISE EXCEPTION 'INVALID_SCHOOL_PROFILE' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='SCHOOL_PROFILE_UPDATE' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  SELECT * INTO cur FROM public.truong WHERE ma_truong=1 FOR UPDATE;
  IF cur.phien_ban<>p_expected_version THEN RAISE EXCEPTION 'SCHOOL_PROFILE_VERSION_CONFLICT' USING ERRCODE='23514'; END IF;
  IF EXISTS(SELECT 1 FROM jsonb_object_keys(p_data) x(key)
            WHERE key NOT IN ('name','shortName','governingBody','address','phone','email','principal')) THEN
    RAISE EXCEPTION 'INVALID_SCHOOL_PROFILE' USING ERRCODE='23514'; END IF;
  FOREACH k IN ARRAY ARRAY['name','shortName','governingBody','address','phone','email','principal'] LOOP
    IF p_data ? k AND jsonb_typeof(p_data->k) NOT IN ('string','null') THEN
      RAISE EXCEPTION 'INVALID_SCHOOL_PROFILE' USING ERRCODE='23514'; END IF;
    vals:=vals||jsonb_build_object(k,nullif(btrim(coalesce(p_data->>k,'')),''));
  END LOOP;
  IF length(coalesce(vals->>'name',''))<3 OR length(vals->>'name')>200
     OR length(coalesce(vals->>'shortName',''))<2 OR length(vals->>'shortName')>60
     OR length(vals->>'governingBody')>200 OR length(vals->>'address')>300 OR length(vals->>'principal')>120
     OR ((vals->>'phone') IS NOT NULL AND (vals->>'phone') !~ '^[0-9]{10,11}$')
     OR ((vals->>'email') IS NOT NULL AND ((vals->>'email') !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' OR length(vals->>'email')>200)) THEN
    RAISE EXCEPTION 'INVALID_SCHOOL_PROFILE' USING ERRCODE='23514'; END IF;
  UPDATE public.truong SET ten_truong=vals->>'name',ten_ngan=vals->>'shortName',co_quan_chu_quan=vals->>'governingBody',
    dia_chi=vals->>'address',dien_thoai=vals->>'phone',email=vals->>'email',hieu_truong=vals->>'principal',
    phien_ban=phien_ban+1,cap_nhat_luc=now(),nguoi_cap_nhat=actor_id WHERE ma_truong=1;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'SCHOOL_PROFILE_UPDATED','truong:1');
  result:=jsonb_build_object('version',cur.phien_ban+1);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'SCHOOL_PROFILE_UPDATE',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.cap_nhat_thong_tin_truong(text,integer,jsonb,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cap_nhat_thong_tin_truong(text,integer,jsonb,text,text) TO app_runtime;

-- Đặt hoặc gỡ logo (p_logo_key NULL = gỡ). File cũ trong kho được giữ lại.
CREATE FUNCTION public.dat_logo_truong(p_phien text,p_expected_version integer,p_logo_key text,p_content_type text,p_checksum text,p_idem text,p_hash text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer; cur public.truong; prior public.khoa_idempotency; result jsonb;
BEGIN
  IF current_setting('transaction_isolation')<>'serializable' THEN RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001'; END IF;
  IF p_expected_version IS NULL OR p_hash IS NULL OR p_hash !~ '^[0-9a-f]{64}$'
     OR p_idem IS NULL OR length(p_idem) NOT BETWEEN 1 AND 64 OR p_idem !~ '^[a-zA-Z0-9_-]+$'
     OR (p_logo_key IS NULL AND (p_content_type IS NOT NULL OR p_checksum IS NOT NULL))
     OR (p_logo_key IS NOT NULL AND (p_logo_key !~ '^school/logo-[0-9a-f]{64}\.(png|jpg)$'
         OR p_content_type NOT IN ('image/png','image/jpeg') OR p_checksum IS NULL OR p_checksum !~ '^[0-9a-f]{64}$')) THEN
    RAISE EXCEPTION 'INVALID_LOGO_FILE' USING ERRCODE='23514'; END IF;
  SELECT u.ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec s JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN' AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501'; END IF;
  SELECT * INTO prior FROM public.khoa_idempotency WHERE ma_nguoi_dung=actor_id AND thao_tac='SCHOOL_LOGO_UPDATE' AND khoa=p_idem;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau<>p_hash THEN RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505'; END IF;
    RETURN prior.ket_qua;
  END IF;
  SELECT * INTO cur FROM public.truong WHERE ma_truong=1 FOR UPDATE;
  IF cur.phien_ban<>p_expected_version THEN RAISE EXCEPTION 'SCHOOL_PROFILE_VERSION_CONFLICT' USING ERRCODE='23514'; END IF;
  UPDATE public.truong SET logo_key=p_logo_key,logo_content_type=p_content_type,logo_checksum=p_checksum,
    phien_ban=phien_ban+1,cap_nhat_luc=now(),nguoi_cap_nhat=actor_id WHERE ma_truong=1;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
  VALUES(actor_id,CASE WHEN p_logo_key IS NULL THEN 'SCHOOL_LOGO_REMOVED' ELSE 'SCHOOL_LOGO_UPDATED' END,'truong:1');
  result:=jsonb_build_object('version',cur.phien_ban+1);
  INSERT INTO public.khoa_idempotency(khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua) VALUES(p_idem,actor_id,'SCHOOL_LOGO_UPDATE',p_hash,result);
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION public.dat_logo_truong(text,integer,text,text,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.dat_logo_truong(text,integer,text,text,text,text,text) TO app_runtime;

COMMIT;
