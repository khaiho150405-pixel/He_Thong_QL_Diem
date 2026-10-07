-- ADR-0015: luu_ket_qua_nhan_dien tra học sinh theo danh sách lớp đã chốt của phiếu (danh_sach_phieu),
-- không còn ORDER BY ma_hoc_sinh OFFSET.
--
-- ROLLBACK (không tự động): bản cũ nằm ở 202609120001_recognition_results. Quay lại bằng CREATE OR REPLACE
-- từ file đó chỉ hợp lệ khi chưa có phiếu nào lưu kết quả bằng hàm mới; kết quả đã lưu (stt_giay, ho_ten_doc_duoc...)
-- là bằng chứng ghép dòng nên không xóa. Ưu tiên sửa tiến bằng migration mới.
--
-- Phiếu DANG_XU_LY tạo trước migration 202610060002 không có snapshot: mọi STT bị từ chối
-- (MALFORMED_RECOGNITION_RESULT) và worker đánh dấu phiếu LOI; giáo viên tải lại ảnh.
BEGIN;

CREATE OR REPLACE FUNCTION public.luu_ket_qua_nhan_dien(
  p_ticket bigint,
  p_model_version text,
  p_rows jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  ticket public.phieu_nhan_dien;
  item jsonb;
  row_index integer;
  row_stt integer;
  student_id integer;
  numeric_value numeric;
  written_value numeric;
  numeric_confidence numeric;
  written_confidence numeric;
  match_confidence numeric;
  stt_on_paper integer;
  name_read text;
  match_note text;
  name_crop text;
  row_total integer;
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
  -- Số dòng có điểm ghép được từ 1 đến sĩ số snapshot (dòng gạch/trống bị bỏ, trang chỉ chứa một đoạn lớp).
  row_total := jsonb_array_length(p_rows);
  IF row_total NOT BETWEEN 1 AND ticket.so_dong_khai_bao THEN
    RAISE EXCEPTION 'GRID_ROW_COUNT_MISMATCH' USING ERRCODE='23514';
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
    IF jsonb_typeof(item) <> 'object'
       OR NOT (item ?& ARRAY['order','stt','comparison','reviewLevel','numericCropKey','writtenCropKey','numeric','written'])
       OR jsonb_typeof(item->'order') <> 'number'
       OR jsonb_typeof(item->'stt') <> 'number'
       OR (item->>'order') !~ '^[1-9][0-9]{0,3}$'
       OR (item->>'stt') !~ '^[1-9][0-9]{0,8}$'
       OR jsonb_typeof(item->'comparison') <> 'string'
       OR jsonb_typeof(item->'reviewLevel') <> 'string'
       OR item->>'comparison' NOT IN ('KHOP','LECH','MOT_KENH','KHONG_DOC_DUOC')
       OR item->>'reviewLevel' NOT IN ('XANH','VANG','DO')
       OR jsonb_typeof(item->'numericCropKey') <> 'string'
       OR jsonb_typeof(item->'writtenCropKey') <> 'string'
       OR item->>'numericCropKey' !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-numeric[.]png$')
       OR item->>'writtenCropKey' !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-written[.]png$')
       OR jsonb_typeof(item->'numeric') <> 'object'
       OR jsonb_typeof(item->'written') <> 'object'
       -- Trường ghép tùy chọn: vắng hoặc null; nếu có thì phải đúng kiểu.
       OR (item ? 'sttOnPaper' AND jsonb_typeof(item->'sttOnPaper') NOT IN ('null','number'))
       OR (item ? 'nameRead' AND jsonb_typeof(item->'nameRead') NOT IN ('null','string'))
       OR (item ? 'matchConfidence' AND jsonb_typeof(item->'matchConfidence') NOT IN ('null','number'))
       OR (item ? 'matchNote' AND jsonb_typeof(item->'matchNote') NOT IN ('null','string'))
       OR (item ? 'nameCropKey' AND jsonb_typeof(item->'nameCropKey') NOT IN ('null','string')) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    row_index := (item->>'order')::integer;
    row_stt := (item->>'stt')::integer;
    stt_on_paper := CASE WHEN jsonb_typeof(item->'sttOnPaper')='number' THEN
      CASE WHEN (item->>'sttOnPaper') ~ '^[1-9][0-9]{0,8}$' THEN (item->>'sttOnPaper')::integer
           ELSE -1 END END;
    name_read := CASE WHEN jsonb_typeof(item->'nameRead')='string' THEN item->>'nameRead' END;
    match_note := CASE WHEN jsonb_typeof(item->'matchNote')='string' THEN item->>'matchNote' END;
    name_crop := CASE WHEN jsonb_typeof(item->'nameCropKey')='string' THEN item->>'nameCropKey' END;
    match_confidence := CASE WHEN jsonb_typeof(item->'matchConfidence')='number'
      THEN (item->>'matchConfidence')::numeric END;
    IF stt_on_paper = -1
       OR length(name_read) > 150
       OR length(match_note) > 200
       OR match_confidence NOT BETWEEN 0 AND 1
       OR (name_crop IS NOT NULL AND name_crop !~ ('^recognition/crops/'||p_ticket::text||'/[0-9]+-name[.]png$'))
       OR EXISTS (SELECT 1 FROM public.ket_qua_dong
                  WHERE ma_phieu=p_ticket AND thu_tu_dong=row_index) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
    END IF;

    -- Học sinh lấy từ danh sách lớp đã chốt khi tạo phiếu; STT ngoài snapshot hoặc dùng hai lần bị từ chối.
    SELECT ds.ma_hoc_sinh INTO student_id FROM public.danh_sach_phieu ds
    WHERE ds.ma_phieu=p_ticket AND ds.stt=row_stt;
    IF student_id IS NULL
       OR EXISTS (SELECT 1 FROM public.ket_qua_dong
                  WHERE ma_phieu=p_ticket AND ma_hoc_sinh=student_id) THEN
      RAISE EXCEPTION 'MALFORMED_RECOGNITION_RESULT' USING ERRCODE='23514';
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
      do_tin_cay_a,do_tin_cay_b,ket_luan_doi_chieu,muc_phan_loai,
      stt_giay,ho_ten_doc_duoc,do_tin_cay_ghep,duong_dan_anh_o_ten,ghi_chu_ghep
    ) VALUES (
      p_ticket,student_id,row_index,
      item->>'numericCropKey',item->>'writtenCropKey',
      item->'numeric'->>'rawOutput',item->'written'->>'rawOutput',
      numeric_value,written_value,numeric_confidence,written_confidence,
      (item->>'comparison')::public."KetLuan",
      (item->>'reviewLevel')::public."MucPhanLoai",
      stt_on_paper,name_read,match_confidence,name_crop,match_note
    );
  END LOOP;

  UPDATE public.phieu_nhan_dien SET
    so_dong_nhan_dien=row_total,
    phien_ban_mo_hinh=p_model_version,
    trang_thai='CHO_DOI_CHIEU',ma_loi=NULL,version=version+1
  WHERE ma_phieu=p_ticket;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(ticket.nguoi_tai,'RECOGNITION_COMPLETED','phieu_nhan_dien:'||p_ticket::text);
END $$;

REVOKE ALL ON FUNCTION public.luu_ket_qua_nhan_dien(bigint,text,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.luu_ket_qua_nhan_dien(bigint,text,jsonb) TO app_runtime;

COMMIT;
