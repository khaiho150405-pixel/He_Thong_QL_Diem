-- Allow the timetable to include Sunday. Existing rows and unique indexes remain valid.
ALTER TABLE public.thoi_khoa_bieu
  DROP CONSTRAINT thoi_khoa_bieu_thu_check;
ALTER TABLE public.thoi_khoa_bieu
  ADD CONSTRAINT thoi_khoa_bieu_thu_check CHECK (thu BETWEEN 2 AND 8);

-- Rollback: restore CHECK (thu BETWEEN 2 AND 7) after removing any Sunday rows.
