-- Vá phiếu điều chỉnh (ADR-0017): cap_nhat_diem tự kiểm cột đã chốt (cờ qld.dieu_chinh_sau_chot chỉ còn tác dụng với
-- duyet_phieu_dieu_chinh) và công bố bị chặn khi còn phiếu điều chỉnh CHO_DUYET.
-- dat_mien_diem đã có kiểm chot_cot_diem tường minh (COLUMN_NOT_OPEN) nên giữ nguyên.
--
-- ROLLBACK (chỉ tiến): khôi phục cap_nhat_diem (202610210003_cell_exempt) và kiem_san_sang_cong_bo (202610220001_adjustments).
BEGIN;

-- Phần còn lại giữ nguyên từ 202610210003_cell_exempt.
CREATE OR REPLACE FUNCTION public.cap_nhat_diem(p_phien text, p_book integer, p_version integer, p_changes jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE b public.bang_diem; d public.diem_thanh_phan; c jsonb; v numeric;
 actor_id integer; items jsonb:='[]'::jsonb; seen bigint[]:='{}'; cell_id bigint; reason text;
BEGIN
 b:=public.kiem_quyen_ghi_bang(p_phien,p_book,p_version);
 SELECT ma_nguoi_dung INTO actor_id FROM public.phien_lam_viec WHERE ma_bam=p_phien;
 IF p_changes IS NULL OR jsonb_typeof(p_changes)<>'array' THEN
   RAISE EXCEPTION 'INVALID_CHANGES' USING ERRCODE='23514'; END IF;
 IF jsonb_array_length(p_changes) NOT BETWEEN 1 AND 100 THEN
   RAISE EXCEPTION 'INVALID_BATCH_SIZE' USING ERRCODE='23514'; END IF;
 FOR c IN SELECT value FROM jsonb_array_elements(p_changes) LOOP
   IF jsonb_typeof(c)<>'object' OR NOT (c ?& ARRAY['cellId','value','reason'])
   OR (c-ARRAY['cellId','value','reason'])<>'{}'::jsonb
   OR jsonb_typeof(c->'cellId')<>'string' OR (c->>'cellId')!~'^[1-9][0-9]{0,18}$'
   OR jsonb_typeof(c->'reason')<>'string' THEN
     RAISE EXCEPTION 'INVALID_CHANGE' USING ERRCODE='23514'; END IF;
   cell_id:=(c->>'cellId')::bigint;
   IF cell_id=ANY(seen) THEN RAISE EXCEPTION 'DUPLICATE_CELL' USING ERRCODE='23514'; END IF;
   seen:=array_append(seen,cell_id);
   reason:=btrim(c->>'reason');
   IF length(reason) NOT BETWEEN 1 AND 500 THEN RAISE EXCEPTION 'INVALID_REASON' USING ERRCODE='23514'; END IF;
   IF c->'value'='null'::jsonb THEN v:=NULL;
   ELSE
     IF jsonb_typeof(c->'value')<>'string' OR (c->>'value')!~'^(10[.]0|[0-9][.][0-9])$' THEN
       RAISE EXCEPTION 'INVALID_GRADE' USING ERRCODE='23514'; END IF;
     v:=public.kiem_tra_gia_tri_diem((c->>'value')::numeric);
   END IF;
   SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id AND ma_bang_diem=p_book;
   IF NOT FOUND THEN RAISE EXCEPTION 'CELL_OUTSIDE_BOOK' USING ERRCODE='P0002'; END IF;
   IF d.trang_thai='MIEN' THEN RAISE EXCEPTION 'CELL_EXEMPT' USING ERRCODE='23514'; END IF;
   PERFORM public.kiem_thoi_gian_nhap(p_book,d.ma_thanh_phan);
   -- Cột đã chốt chỉ sửa được qua phiếu điều chỉnh (duyet_phieu_dieu_chinh), không phụ thuộc trigger kiem_cot_diem.
   IF EXISTS(SELECT 1 FROM public.chot_cot_diem WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan) THEN
     RAISE EXCEPTION 'COLUMN_LOCKED' USING ERRCODE='23514'; END IF;
   IF NOT EXISTS(SELECT 1 FROM public.hoc_sinh WHERE ma_hoc_sinh=d.ma_hoc_sinh AND ma_lop=b.ma_lop AND dang_theo_hoc)
   OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon)
   -- Kiểm tra cột điểm có đang được Admin cho phép nhập không
   OR NOT EXISTS(SELECT 1 FROM public.thanh_phan_diem WHERE ma_thanh_phan=d.ma_thanh_phan AND ma_mon=b.ma_mon AND cho_phep_nhap)
   OR d.trang_thai='CHO_DOI_CHIEU' OR EXISTS(SELECT 1 FROM public.phieu_nhan_dien
     WHERE ma_bang_diem=p_book AND ma_thanh_phan=d.ma_thanh_phan AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU')) THEN
     RAISE EXCEPTION 'CELL_NOT_EDITABLE' USING ERRCODE='23514'; END IF;
   IF d.gia_tri IS DISTINCT FROM v THEN
     UPDATE public.diem_thanh_phan SET gia_tri=v,
       trang_thai=CASE WHEN v IS NULL THEN 'CHUA_CO'::public."TrangThaiDiem" ELSE 'DA_DUYET'::public."TrangThaiDiem" END,
       nguon_nhap='NHAP_TAY' WHERE ma_diem=cell_id;
     INSERT INTO public.lich_su_sua_diem(ma_diem,nguoi_sua,gia_tri_cu,gia_tri_moi,ly_do)
       VALUES(cell_id,actor_id,d.gia_tri,v,reason);
   END IF;
   SELECT * INTO d FROM public.diem_thanh_phan WHERE ma_diem=cell_id;
   items:=items || jsonb_build_array(jsonb_build_object('id',d.ma_diem::text,
     'value',d.gia_tri::text,'status',d.trang_thai,'source',d.nguon_nhap));
 END LOOP;
 UPDATE public.bang_diem SET version=version+1 WHERE ma_bang_diem=p_book;
 INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong) VALUES(actor_id,'GRADES_UPDATED','bang_diem:'||p_book);
 RETURN jsonb_build_object('items',items,'bookId',p_book,'version',b.version+1);
END $$;

-- Phần còn lại giữ nguyên từ 202610220001_adjustments.
CREATE OR REPLACE FUNCTION public.kiem_san_sang_cong_bo(p_term integer) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE a record; b public.bang_diem; issues jsonb:='[]'::jsonb; missing integer[]; without_result integer[];
  n integer; assignments integer:=0; blocking boolean:=false;
BEGIN
  FOR a IN SELECT pc.ma_lop,pc.ma_mon,l.ten_lop,m.ten_mon
    FROM public.phan_cong_giang_day pc JOIN public.lop l ON l.ma_lop=pc.ma_lop JOIN public.mon_hoc m ON m.ma_mon=pc.ma_mon
    WHERE pc.ma_hoc_ky=p_term ORDER BY l.ten_lop,m.ten_mon,pc.ma_lop,pc.ma_mon LOOP
    assignments:=assignments+1;
    SELECT * INTO b FROM public.bang_diem WHERE ma_lop=a.ma_lop AND ma_mon=a.ma_mon AND ma_hoc_ky=p_term;
    IF NOT FOUND THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('GRADEBOOK_MISSING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,NULL,NULL,NULL));
      blocking:=true; CONTINUE;
    END IF;
    IF b.trang_thai<>'DA_CHOT' THEN
      SELECT count(*)::integer INTO n FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon
        AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan);
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('GRADEBOOK_NOT_LOCKED','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      blocking:=true;
      SELECT count(*)::integer INTO n FROM public.thanh_phan_diem t WHERE t.ma_mon=b.ma_mon
        AND NOT EXISTS(SELECT 1 FROM public.chot_cot_diem c WHERE c.ma_bang_diem=b.ma_bang_diem AND c.ma_thanh_phan=t.ma_thanh_phan)
        AND NOT EXISTS(SELECT 1 FROM public.lich_hieu_luc(b.ma_bang_diem,t.ma_thanh_phan));
      IF n>0 THEN
        issues:=issues||jsonb_build_array(public.van_de_cong_bo('COLUMNS_WITHOUT_DEADLINE','WARNING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      END IF;
    END IF;
    IF b.can_tinh_lai_tong_ket THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('RESULTS_OUTDATED','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,NULL));
      blocking:=true;
    END IF;
    SELECT count(*)::integer INTO n FROM public.phieu_dieu_chinh WHERE ma_bang_diem=b.ma_bang_diem AND trang_thai='CHO_DUYET';
    IF n>0 THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('ADJUSTMENT_PENDING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      blocking:=true;
    END IF;
    SELECT count(*)::integer INTO n FROM public.phieu_nhan_dien WHERE ma_bang_diem=b.ma_bang_diem AND trang_thai IN ('DANG_XU_LY','CHO_DOI_CHIEU');
    IF n>0 THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('RECOGNITION_PENDING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,NULL,n));
      blocking:=true;
    END IF;
    SELECT array_agg(s.ma_hoc_sinh ORDER BY s.ma_hoc_sinh) INTO missing FROM public.hoc_sinh_thieu_o(b.ma_bang_diem) s;
    IF missing IS NOT NULL THEN
      issues:=issues||jsonb_build_array(public.van_de_cong_bo('STUDENT_NOT_IN_GRADEBOOK','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,missing,cardinality(missing)));
      blocking:=true;
    END IF;
    IF b.trang_thai='DA_CHOT' THEN
      SELECT array_agg(hs.ma_hoc_sinh ORDER BY hs.ma_hoc_sinh) INTO without_result
      FROM public.hoc_sinh hs
      WHERE hs.ma_lop=b.ma_lop AND hs.dang_theo_hoc
        AND NOT (hs.ma_hoc_sinh=ANY(coalesce(missing,'{}'::integer[])))
        AND EXISTS(SELECT 1 FROM public.diem_thanh_phan d WHERE d.ma_bang_diem=b.ma_bang_diem
          AND d.ma_hoc_sinh=hs.ma_hoc_sinh AND d.trang_thai<>'MIEN')
        AND NOT EXISTS(SELECT 1 FROM public.ket_qua_tong_ket k WHERE k.ma_hoc_sinh=hs.ma_hoc_sinh
          AND k.ma_mon=b.ma_mon AND k.ma_hoc_ky=b.ma_hoc_ky);
      IF without_result IS NOT NULL THEN
        issues:=issues||jsonb_build_array(public.van_de_cong_bo('RESULTS_MISSING','BLOCKING',a.ma_lop,a.ten_lop,a.ma_mon,a.ten_mon,b.ma_bang_diem,without_result,cardinality(without_result)));
        blocking:=true;
      END IF;
    END IF;
  END LOOP;
  RETURN jsonb_build_object('ready',assignments>0 AND NOT blocking,'issues',issues);
END $$;
COMMIT;
