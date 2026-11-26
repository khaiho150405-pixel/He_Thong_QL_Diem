-- Quyết định chủ dự án 27/11/2026 (ADR-0024): phiên web 3 ngày, phiên app 7 ngày, không đăng xuất vì không thao
-- tác trước khi phiên hết hạn. Thời hạn tuyệt đối nằm ở phien_lam_viec.het_han do API đặt.
-- Rollback: chạy lại khối này với hai khoảng thời gian đổi chỗ ('7 days' về '30 minutes').
BEGIN;

DO $$
DECLARE f record; definition text;
BEGIN
  FOR f IN SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.prosrc ~ 'hoat_dong_cuoi\s*>' ORDER BY p.proname LOOP
    definition:=regexp_replace(pg_get_functiondef(f.oid),
      '(hoat_dong_cuoi\s*>\s*(statement_timestamp|clock_timestamp)\(\)\s*-\s*)interval ''30 minutes''',
      '\1interval ''7 days''','g');
    EXECUTE definition;
  END LOOP;
  IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.prosrc ~ 'hoat_dong_cuoi' AND p.prosrc ~ '30 minutes') THEN
    RAISE EXCEPTION 'SESSION_IDLE_NOT_UPDATED';
  END IF;
END $$;

COMMIT;
