-- UC13: atomically approve recognition evidence into official grades.
BEGIN;

CREATE FUNCTION public.duyet_phieu_nhan_dien(
  p_phien text,
  p_book integer,
  p_ticket bigint,
  p_ticket_version integer,
  p_book_version integer,
  p_decisions jsonb,
  p_idempotency_key text,
  p_request_hash text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  b public.bang_diem;
  ticket public.phieu_nhan_dien;
  evidence public.ket_qua_dong;
  grade public.diem_thanh_phan;
  prior public.khoa_idempotency;
  item jsonb;
  actor_id integer;
  row_id bigint;
  final_value numeric;
  reason text;
  seen bigint[] := '{}';
  reviewed integer := 0;
  machine_matched integer := 0;
  error_rows integer := 0;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_ticket_version < 0 OR p_book_version < 0
     OR p_request_hash !~ '^[0-9a-f]{64}$'
     OR length(p_idempotency_key) NOT BETWEEN 1 AND 64
     OR p_idempotency_key !~ '^[a-zA-Z0-9_-]+$'
     OR jsonb_typeof(p_decisions) <> 'array'
     OR jsonb_array_length(p_decisions) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'INVALID_REVIEW_REQUEST' USING ERRCODE='23514';
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
  IF NOT EXISTS (SELECT 1 FROM public.phan_cong_giang_day pc
    WHERE pc.ma_giao_vien=actor_id AND pc.ma_lop=b.ma_lop
      AND pc.ma_mon=b.ma_mon AND pc.ma_hoc_ky=b.ma_hoc_ky) THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO prior FROM public.khoa_idempotency
  WHERE ma_nguoi_dung=actor_id AND thao_tac='RECOGNITION_APPROVE'
    AND khoa=p_idempotency_key;
  IF FOUND THEN
    IF prior.ma_bam_yeu_cau <> p_request_hash THEN
      RAISE EXCEPTION 'IDEMPOTENCY_MISMATCH' USING ERRCODE='23505';
    END IF;
    RETURN prior.ket_qua;
  END IF;

  IF b.trang_thai <> 'DANG_NHAP_LIEU' OR b.version <> p_book_version THEN
    RAISE EXCEPTION 'GRADEBOOK_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  SELECT * INTO ticket FROM public.phieu_nhan_dien
  WHERE ma_phieu=p_ticket AND ma_bang_diem=p_book FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'TICKET_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF ticket.trang_thai <> 'CHO_DOI_CHIEU'
     OR ticket.version <> p_ticket_version THEN
    RAISE EXCEPTION 'TICKET_VERSION_OR_STATE_CONFLICT' USING ERRCODE='23514';
  END IF;
  IF jsonb_array_length(p_decisions) <>
     (SELECT count(*) FROM public.ket_qua_dong WHERE ma_phieu=p_ticket) THEN
    RAISE EXCEPTION 'ALL_ROWS_REQUIRED' USING ERRCODE='23514';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_decisions) LOOP
    IF jsonb_typeof(item) <> 'object'
       OR NOT (item ?& ARRAY['rowId','value','reason'])
       OR (item-ARRAY['rowId','value','reason']) <> '{}'::jsonb
       OR jsonb_typeof(item->'rowId') <> 'string'
       OR (item->>'rowId') !~ '^[1-9][0-9]{0,18}$'
       OR (item->>'rowId')::numeric > 9223372036854775807
       OR jsonb_typeof(item->'reason') <> 'string' THEN
      RAISE EXCEPTION 'INVALID_REVIEW_DECISION' USING ERRCODE='23514';
    END IF;
    row_id := (item->>'rowId')::bigint;
    IF row_id=ANY(seen) THEN
      RAISE EXCEPTION 'DUPLICATE_REVIEW_ROW' USING ERRCODE='23514';
    END IF;
    seen := array_append(seen,row_id);
    reason := btrim(item->>'reason');
    IF length(reason) NOT BETWEEN 1 AND 500 THEN
      RAISE EXCEPTION 'INVALID_REVIEW_REASON' USING ERRCODE='23514';
    END IF;
    IF item->'value'='null'::jsonb THEN
      final_value := NULL;
    ELSE
      IF jsonb_typeof(item->'value') <> 'string'
         OR (item->>'value') !~ '^(10[.]0|[0-9][.][0-9])$' THEN
        RAISE EXCEPTION 'INVALID_REVIEW_GRADE' USING ERRCODE='23514';
      END IF;
      final_value := public.kiem_tra_gia_tri_diem((item->>'value')::numeric);
    END IF;

    SELECT * INTO evidence FROM public.ket_qua_dong
    WHERE ma_dong=row_id AND ma_phieu=p_ticket FOR UPDATE;
    IF NOT FOUND OR evidence.nguoi_duyet IS NOT NULL OR evidence.ma_diem IS NOT NULL THEN
      RAISE EXCEPTION 'REVIEW_ROW_NOT_AVAILABLE' USING ERRCODE='P0002';
    END IF;
    SELECT d.* INTO grade FROM public.diem_thanh_phan d
    JOIN public.hoc_sinh hs ON hs.ma_hoc_sinh=d.ma_hoc_sinh
    WHERE d.ma_bang_diem=p_book
      AND d.ma_hoc_sinh=evidence.ma_hoc_sinh
      AND d.ma_thanh_phan=ticket.ma_thanh_phan
      AND hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
    FOR UPDATE OF d;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'GRADE_CELL_NOT_FOUND' USING ERRCODE='P0002';
    END IF;

    IF grade.gia_tri IS DISTINCT FROM final_value THEN
      INSERT INTO public.lich_su_sua_diem(
        ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do
      ) VALUES (grade.ma_diem,actor_id,grade.gia_tri,final_value,reason);
    END IF;
    UPDATE public.diem_thanh_phan SET
      gia_tri=final_value,
      trang_thai=CASE WHEN final_value IS NULL
        THEN 'CHUA_CO'::public."TrangThaiDiem"
        ELSE 'DA_DUYET'::public."TrangThaiDiem" END,
      nguon_nhap='NHAN_DIEN'
    WHERE ma_diem=grade.ma_diem;
    UPDATE public.ket_qua_dong SET
      ma_diem=grade.ma_diem,
      gia_tri_chot=final_value,
      nguoi_duyet=actor_id,
      thoi_diem_duyet=statement_timestamp()
    WHERE ma_dong=row_id;

    reviewed := reviewed+1;
    IF evidence.muc_phan_loai='XANH'
       AND final_value IS NOT DISTINCT FROM evidence.gia_tri_kenh_a
       AND final_value IS NOT DISTINCT FROM evidence.gia_tri_kenh_b THEN
      machine_matched := machine_matched+1;
    END IF;
    IF evidence.muc_phan_loai='DO' THEN error_rows := error_rows+1; END IF;
  END LOOP;

  UPDATE public.phieu_nhan_dien SET
    trang_thai='DA_DUYET',version=version+1
  WHERE ma_phieu=p_ticket;
  UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,'RECOGNITION_APPROVED','phieu_nhan_dien:'||p_ticket::text);
  result := jsonb_build_object(
    'ticketId',p_ticket::text,
    'ticketVersion',ticket.version+1,
    'gradebookId',p_book,
    'gradebookVersion',b.version+1,
    'reviewedRows',reviewed,
    'machineMatchedRows',machine_matched,
    'humanCorrectedRows',reviewed-machine_matched,
    'errorRows',error_rows,
    'status','DA_DUYET'
  );
  INSERT INTO public.khoa_idempotency(
    khoa,ma_nguoi_dung,thao_tac,ma_bam_yeu_cau,ket_qua
  ) VALUES (
    p_idempotency_key,actor_id,'RECOGNITION_APPROVE',p_request_hash,result
  );
  RETURN result;
END $$;

REVOKE ALL ON FUNCTION public.duyet_phieu_nhan_dien(
  text,integer,bigint,integer,integer,jsonb,text,text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.duyet_phieu_nhan_dien(
  text,integer,bigint,integer,integer,jsonb,text,text
) TO app_runtime;

-- Forward-only rollback: revoke EXECUTE in a later migration; preserve grades,
-- row decisions, history, audit and idempotency evidence already committed.
COMMIT;
