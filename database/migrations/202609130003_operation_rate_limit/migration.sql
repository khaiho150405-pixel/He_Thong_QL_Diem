-- Phase 6: shared, atomic rate limiting for sensitive operations.
BEGIN;

CREATE TABLE public.gioi_han_tac_vu (
  ma_nguoi_dung INTEGER NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung)
    ON DELETE CASCADE ON UPDATE RESTRICT,
  thao_tac VARCHAR(32) NOT NULL,
  bat_dau_cua_so TIMESTAMPTZ(6) NOT NULL,
  so_lan INTEGER NOT NULL,
  PRIMARY KEY (ma_nguoi_dung, thao_tac),
  CONSTRAINT gioi_han_tac_vu_hop_le CHECK (
    thao_tac = 'RECOGNITION_UPLOAD' AND so_lan BETWEEN 1 AND 1001
  )
);

CREATE FUNCTION public.tieu_thu_han_muc_tac_vu(
  p_phien text,
  p_thao_tac text,
  p_gioi_han integer,
  p_cua_so_giay integer
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog AS $$
DECLARE
  actor_id integer;
  allowed boolean;
BEGIN
  IF p_thao_tac <> 'RECOGNITION_UPLOAD'
     OR p_gioi_han NOT BETWEEN 1 AND 1000
     OR p_cua_so_giay NOT BETWEEN 1 AND 3600 THEN
    RAISE EXCEPTION 'INVALID_OPERATION_RATE_LIMIT' USING ERRCODE='23514';
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

  INSERT INTO public.gioi_han_tac_vu(
    ma_nguoi_dung,thao_tac,bat_dau_cua_so,so_lan
  ) VALUES(actor_id,p_thao_tac,statement_timestamp(),1)
  ON CONFLICT (ma_nguoi_dung,thao_tac) DO UPDATE SET
    bat_dau_cua_so=CASE
      WHEN public.gioi_han_tac_vu.bat_dau_cua_so
        + make_interval(secs=>p_cua_so_giay) <= statement_timestamp()
      THEN statement_timestamp()
      ELSE public.gioi_han_tac_vu.bat_dau_cua_so
    END,
    so_lan=CASE
      WHEN public.gioi_han_tac_vu.bat_dau_cua_so
        + make_interval(secs=>p_cua_so_giay) <= statement_timestamp()
      THEN 1
      ELSE LEAST(public.gioi_han_tac_vu.so_lan+1,p_gioi_han+1)
    END
  RETURNING so_lan<=p_gioi_han INTO allowed;
  RETURN allowed;
END $$;

REVOKE ALL ON TABLE public.gioi_han_tac_vu FROM PUBLIC, app_runtime;
REVOKE ALL ON FUNCTION public.tieu_thu_han_muc_tac_vu(text,text,integer,integer)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.tieu_thu_han_muc_tac_vu(text,text,integer,integer)
  TO app_runtime;

-- Forward-only rollback: revoke function execution in a later migration and
-- retain counters until the configured security-data retention period expires.
COMMIT;
