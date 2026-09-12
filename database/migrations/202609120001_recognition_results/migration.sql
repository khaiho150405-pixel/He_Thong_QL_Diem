-- UC12: persist model evidence for human review without writing official grades.
BEGIN;

CREATE FUNCTION public.luu_ket_qua_nhan_dien(
  p_ticket bigint,
  p_model_version text,
  p_rows jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  ticket public.phieu_nhan_dien;
  item jsonb;
  row_index integer;
  student_id integer;
  numeric_value numeric;
  written_value numeric;
  numeric_confidence numeric;
  written_confidence numeric;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF length(p_model_version) NOT BETWEEN 1 AND 80
     OR jsonb_typeof(p_rows) <> 'array' THEN
    RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
  END IF;

  SELECT * INTO ticket FROM public.phieu_nhan_dien
  WHERE ma_phieu=p_ticket FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'TICKET_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF ticket.trang_thai IN ('CHO_DOI_CHIEU','DA_DUYET') THEN RETURN; END IF;
  IF ticket.trang_thai <> 'DANG_XU_LY' THEN
    RAISE EXCEPTION 'TICKET_NOT_PROCESSING' USING ERRCODE='23514';
  END IF;
  IF jsonb_array_length(p_rows) <> ticket.so_dong_khai_bao THEN
    RAISE EXCEPTION 'GRID_ROW_COUNT_MISMATCH' USING ERRCODE='23514';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
    row_index := (item->>'order')::integer;
    IF row_index < 1 OR row_index > ticket.so_dong_khai_bao
       OR EXISTS (SELECT 1 FROM public.ket_qua_dong
                  WHERE ma_phieu=p_ticket AND thu_tu_dong=row_index)
       OR item->>'comparison' NOT IN ('KHOP','LECH','MOT_KENH','KHONG_DOC_DUOC')
       OR item->>'reviewLevel' NOT IN ('XANH','VANG','DO')
       OR item->>'numericCropKey' !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-numeric[.]png$')
       OR item->>'writtenCropKey' !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-written[.]png$') THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    SELECT hs.ma_hoc_sinh INTO student_id FROM public.bang_diem b
    JOIN public.hoc_sinh hs ON hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
    WHERE b.ma_bang_diem=ticket.ma_bang_diem
    ORDER BY hs.ma_hoc_sinh OFFSET row_index-1 LIMIT 1;
    IF student_id IS NULL THEN
      RAISE EXCEPTION 'GRID_ROW_COUNT_MISMATCH' USING ERRCODE='23514';
    END IF;

    numeric_value := CASE WHEN item->'numeric'->>'value' IS NULL THEN NULL
      ELSE public.kiem_tra_gia_tri_diem((item->'numeric'->>'value')::numeric) END;
    written_value := CASE WHEN item->'written'->>'value' IS NULL THEN NULL
      ELSE public.kiem_tra_gia_tri_diem((item->'written'->>'value')::numeric) END;
    numeric_confidence := CASE WHEN item->'numeric'->>'confidence' IS NULL THEN NULL
      ELSE (item->'numeric'->>'confidence')::numeric END;
    written_confidence := CASE WHEN item->'written'->>'confidence' IS NULL THEN NULL
      ELSE (item->'written'->>'confidence')::numeric END;
    IF numeric_confidence NOT BETWEEN 0 AND 1 OR written_confidence NOT BETWEEN 0 AND 1
       OR ((item->'numeric'->>'isBlank')::boolean AND numeric_value IS NOT NULL)
       OR ((item->'written'->>'isBlank')::boolean AND written_value IS NOT NULL) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    INSERT INTO public.ket_qua_dong(
      ma_phieu,ma_hoc_sinh,thu_tu_dong,
      duong_dan_anh_o_so,duong_dan_anh_o_chu,
      raw_kenh_a,raw_kenh_b,gia_tri_kenh_a,gia_tri_kenh_b,
      do_tin_cay_a,do_tin_cay_b,ket_luan_doi_chieu,muc_phan_loai
    ) VALUES (
      p_ticket,student_id,row_index,
      item->>'numericCropKey',item->>'writtenCropKey',
      item->'numeric'->>'rawOutput',item->'written'->>'rawOutput',
      numeric_value,written_value,numeric_confidence,written_confidence,
      (item->>'comparison')::public."KetLuan",
      (item->>'reviewLevel')::public."MucPhanLoai"
    );
  END LOOP;

  UPDATE public.phieu_nhan_dien SET
    so_dong_nhan_dien=so_dong_khai_bao,
    phien_ban_mo_hinh=p_model_version,
    trang_thai='CHO_DOI_CHIEU',ma_loi=NULL,version=version+1
  WHERE ma_phieu=p_ticket;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(ticket.nguoi_tai,'RECOGNITION_COMPLETED','phieu_nhan_dien:'||p_ticket::text);
END $$;

CREATE FUNCTION public.danh_dau_phieu_nhan_dien_loi(
  p_ticket bigint,
  p_code text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE actor_id integer;
BEGIN
  IF p_code !~ '^[A-Z0-9_]{1,80}$' THEN
    RAISE EXCEPTION 'INVALID_ERROR_CODE' USING ERRCODE='23514';
  END IF;
  UPDATE public.phieu_nhan_dien SET trang_thai='LOI',ma_loi=p_code,version=version+1
  WHERE ma_phieu=p_ticket AND trang_thai='DANG_XU_LY'
  RETURNING nguoi_tai INTO actor_id;
  IF actor_id IS NOT NULL THEN
    INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
      VALUES(actor_id,'RECOGNITION_FAILED','phieu_nhan_dien:'||p_ticket::text||':'||p_code);
  END IF;
END $$;

REVOKE ALL ON FUNCTION public.luu_ket_qua_nhan_dien(bigint,text,jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.danh_dau_phieu_nhan_dien_loi(bigint,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.luu_ket_qua_nhan_dien(bigint,text,jsonb),
  public.danh_dau_phieu_nhan_dien_loi(bigint,text) TO app_runtime;

-- Forward-only rollback: revoke worker functions in a later migration; retain
-- recognition evidence and audit rows already created for human review.
COMMIT;
