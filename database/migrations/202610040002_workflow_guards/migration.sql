BEGIN;
-- Repair short legacy component labels before applying the shared semester policy.
UPDATE public.thanh_phan_diem SET loai_he_so=CASE WHEN lower(ten_thanh_phan) LIKE '%gk%' THEN 'GK' WHEN lower(ten_thanh_phan) LIKE '%ck%' THEN 'CK' ELSE loai_he_so END
WHERE loai_he_so='TX' AND (lower(ten_thanh_phan) LIKE '%gk%' OR lower(ten_thanh_phan) LIKE '%ck%');
CREATE FUNCTION public.kiem_bang_cong_bo() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE published boolean;
BEGIN
 SELECT da_cong_bo INTO published FROM public.hoc_ky WHERE ma_hoc_ky=NEW.ma_hoc_ky FOR UPDATE;
 IF published THEN RAISE EXCEPTION 'TERM_ALREADY_PUBLISHED' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER published_term_book BEFORE INSERT ON public.bang_diem FOR EACH ROW EXECUTE FUNCTION public.kiem_bang_cong_bo();
CREATE FUNCTION public.khong_sua_chot_cot() RETURNS trigger LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN RAISE EXCEPTION 'COLUMN_LOCK_APPEND_ONLY' USING ERRCODE='23514'; END $$;
CREATE TRIGGER column_lock_append_only BEFORE UPDATE OR DELETE ON public.chot_cot_diem FOR EACH ROW EXECUTE FUNCTION public.khong_sua_chot_cot();
-- Forward-only. Keep publication and immutable column evidence; disable via reviewed forward migration.
COMMIT;
