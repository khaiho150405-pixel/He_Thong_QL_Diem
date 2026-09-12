-- UC11: upload receipt and durable recognition dispatch.
BEGIN;

CREATE TABLE public.recognition_outbox (
  ma_su_kien BIGSERIAL PRIMARY KEY,
  loai_su_kien VARCHAR(64) NOT NULL,
  ma_phieu BIGINT NOT NULL UNIQUE REFERENCES public.phieu_nhan_dien(ma_phieu) ON DELETE RESTRICT,
  du_lieu JSONB NOT NULL,
  so_lan_thu INTEGER NOT NULL DEFAULT 0 CHECK (so_lan_thu >= 0),
  san_sang_luc TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  khoa_den TIMESTAMPTZ(6),
  da_gui_luc TIMESTAMPTZ(6),
  loi_cuoi VARCHAR(200),
  ngay_tao TIMESTAMPTZ(6) NOT NULL DEFAULT now(),
  CONSTRAINT recognition_outbox_payload CHECK (
    loai_su_kien = 'RECOGNITION_REQUESTED'
    AND jsonb_typeof(du_lieu) = 'object'
    AND du_lieu ?& ARRAY['ticketId','jobId']
  )
);
CREATE INDEX recognition_outbox_ready_idx
  ON public.recognition_outbox(da_gui_luc, san_sang_luc);
GRANT SELECT, UPDATE ON public.recognition_outbox TO app_runtime;

CREATE FUNCTION public.tao_phieu_nhan_dien(
  p_phien text,
  p_book integer,
  p_component integer,
  p_checksum text,
  p_object_key text,
  p_declared_rows integer,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  actor_id integer;
  active_rows integer;
  ticket_id bigint;
  prior public.khoa_idempotency;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_checksum !~ '^[0-9a-f]{64}$' OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR p_object_key !~ '^recognition/original/[0-9a-f-]{36}[.](png|jpg)$'
     OR p_declared_rows <= 0 OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$' THEN
    RAISE EXCEPTION 'INVALID_RECOGNITION_REQUEST' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s
  JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='GIAO_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO b FROM public.bang_diem
  WHERE ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF b.trang_thai <> 'DANG_NHAP_LIEU'
     OR NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
       WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
         AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky)
     OR NOT EXISTS (SELECT 1 FROM public.thanh_phan_diem tp
       WHERE tp.ma_thanh_phan=p_component AND tp.ma_mon=b.ma_mon) THEN
    RAISE EXCEPTION 'FORBIDDEN_OR_STATE_CONFLICT' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_UPLOAD'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  SELECT count(*)::integer INTO active_rows FROM public.hoc_sinh
  WHERE ma_lop=b.ma_lop AND dang_theo_hoc;
  IF active_rows <> p_declared_rows THEN
    RAISE EXCEPTION 'DECLARED_ROW_COUNT_MISMATCH' USING ERRCODE='23514';
  END IF;
  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien WHERE ma_bam_tep=p_checksum) THEN
    RAISE EXCEPTION 'DUPLICATE_FILE' USING ERRCODE='23505';
  END IF;
  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien
    WHERE ma_bang_diem=p_book AND ma_thanh_phan=p_component
      AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
    RAISE EXCEPTION 'RECOGNITION_ALREADY_PENDING' USING ERRCODE='23514';
  END IF;

  INSERT INTO public.phieu_nhan_dien(
    ma_bang_diem,ma_thanh_phan,nguoi_tai,ma_bam_tep,
    duong_dan_anh_goc,so_dong_khai_bao
  ) VALUES (
    p_book,p_component,actor_id,p_checksum,p_object_key,p_declared_rows
  ) RETURNING ma_phieu INTO ticket_id;
  result := jsonb_build_object(
    'ticketId',ticket_id::text,
    'jobId','recognition-'||ticket_id::text,
    'status','DANG_XU_LY',
    'storedObjectKey',p_object_key
  );
  INSERT INTO public.recognition_outbox(loai_su_kien,ma_phieu,du_lieu)
    VALUES('RECOGNITION_REQUESTED',ticket_id,result);
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_UPLOADED','phieu_nhan_dien:'||ticket_id::text);
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_UPLOAD',p_request_hash,result
  );
  RETURN result;
END $$;

CREATE FUNCTION public.xac_nhan_outbox(p_event bigint)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS $$
  UPDATE public.recognition_outbox
  SET da_gui_luc=statement_timestamp(), khoa_den=NULL, loi_cuoi=NULL
  WHERE ma_su_kien=p_event AND da_gui_luc IS NULL;
$$;

CREATE FUNCTION public.that_bai_outbox(p_event bigint,p_error text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE failed_ticket bigint; tries integer;
BEGIN
  UPDATE public.recognition_outbox
  SET khoa_den=NULL,
      san_sang_luc=statement_timestamp() + make_interval(secs => LEAST(60, power(2,so_lan_thu)::integer)),
      loi_cuoi=left(p_error,200),
      da_gui_luc=CASE WHEN so_lan_thu >= 5 THEN statement_timestamp() ELSE NULL END
  WHERE ma_su_kien=p_event AND da_gui_luc IS NULL
  RETURNING ma_phieu,so_lan_thu INTO failed_ticket,tries;
  IF failed_ticket IS NOT NULL AND tries >= 5 THEN
    UPDATE public.phieu_nhan_dien
    SET trang_thai='LOI',ma_loi='QUEUE_UNAVAILABLE',version=version+1
    WHERE ma_phieu=failed_ticket AND trang_thai='DANG_XU_LY';
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.tao_phieu_nhan_dien(
  text,integer,integer,text,text,integer,text,text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tao_phieu_nhan_dien(
  text,integer,integer,text,text,integer,text,text
) TO app_runtime;
REVOKE ALL ON FUNCTION public.xac_nhan_outbox(bigint) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.that_bai_outbox(bigint,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.xac_nhan_outbox(bigint),
  public.that_bai_outbox(bigint,text) TO app_runtime;

-- Forward-only rollback: revoke function/outbox access in a later migration;
-- keep uploaded ticket metadata and audit evidence.
COMMIT;
