-- Công bố học kỳ kiểm theo MỌI phân công của học kỳ (ADR-0014 bổ sung), không chỉ các bảng điểm đang tồn tại:
--   a) có bang_diem; b) bang_diem DA_CHOT; c) không còn phiếu DANG_XU_LY/CHO_DOI_CHIEU;
--   d) mọi học sinh đang học của lớp có ô trong bảng; e) mọi học sinh đang học có ket_qua_tong_ket của môn,
--      trừ học sinh được miễn mọi ô của bảng.
-- Học kỳ không có phân công → NO_RESULTS_TO_PUBLISH. Không xử lý chiều hủy công bố (true → false).
--
-- ROLLBACK (chỉ tiến): khôi phục kiem_cong_bo cũ (202610040001_school_workflow) bằng migration mới nếu cần.
BEGIN;

-- Dựng một mục của danh sách vấn đề (hàm nội bộ, không cấp cho runtime).
CREATE FUNCTION public.van_de_cong_bo(
  p_code text,p_severity text,p_class integer,p_class_name text,p_subject integer,p_subject_name text,
  p_book integer,p_students integer[],p_count integer
) RETURNS jsonb LANGUAGE sql IMMUTABLE SET search_path=pg_catalog AS $$
  SELECT jsonb_build_object('code',p_code,'severity',p_severity,'classId',p_class,'className',p_class_name,
    'subjectId',p_subject,'subjectName',p_subject_name,'gradebookId',p_book,
    'studentIds',to_jsonb(p_students),'count',p_count)
$$;
REVOKE ALL ON FUNCTION public.van_de_cong_bo(text,text,integer,text,integer,text,integer,integer[],integer) FROM PUBLIC;

-- Chỉ đọc: học kỳ đã sẵn sàng công bố chưa và vì sao chưa.
CREATE FUNCTION public.kiem_san_sang_cong_bo(p_term integer) RETURNS jsonb
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
REVOKE ALL ON FUNCTION public.kiem_san_sang_cong_bo(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.kiem_san_sang_cong_bo(integer) TO app_runtime;

CREATE OR REPLACE FUNCTION public.kiem_cong_bo() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE r jsonb; detail jsonb;
BEGIN
 IF NEW.da_cong_bo AND NOT OLD.da_cong_bo THEN
 IF NOT EXISTS(SELECT 1 FROM public.phan_cong_giang_day WHERE ma_hoc_ky=NEW.ma_hoc_ky) THEN RAISE EXCEPTION 'NO_RESULTS_TO_PUBLISH' USING ERRCODE='23514'; END IF;
 PERFORM 1 FROM public.bang_diem WHERE ma_hoc_ky=NEW.ma_hoc_ky ORDER BY ma_bang_diem FOR UPDATE;
 r:=public.kiem_san_sang_cong_bo(NEW.ma_hoc_ky);
 IF NOT (r->>'ready')::boolean THEN
 SELECT coalesce(jsonb_agg(e.i),'[]'::jsonb) INTO detail FROM (
   SELECT i FROM jsonb_array_elements(r->'issues') AS x(i) WHERE i->>'severity'='BLOCKING' LIMIT 50) e;
 RAISE EXCEPTION 'TERM_RESULTS_INCOMPLETE' USING ERRCODE='23514', DETAIL=detail::text; END IF;
 END IF;
 RETURN NEW;
END $$;
COMMIT;
