-- Quản lý mở cổng nhập điểm theo cột điểm (thành phần điểm)
BEGIN;

ALTER TABLE public.thanh_phan_diem
  ADD COLUMN IF NOT EXISTS cho_phep_nhap BOOLEAN NOT NULL DEFAULT true;

-- Cập nhật stored procedure cap_nhat_diem để chặn nhập điểm vào cột bị khóa
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

COMMIT;
