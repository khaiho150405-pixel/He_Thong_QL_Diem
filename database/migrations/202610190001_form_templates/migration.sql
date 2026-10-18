-- Mẫu bảng điểm (ADR-0016 mục 1, phase P2): QTV khai báo mẫu tờ điểm, giáo viên chỉ đọc mẫu đang dùng.
--
--  - Hai enum mới: "TrangThaiMau" (NHAP|DANG_DUNG|NGUNG), "VaiTroCot" (STT|HO_TEN|DIEM|DIEM_CHU|BO_QUA).
--  - mau_bang_diem: ảnh mẫu (khóa object private), chữ ký lưới do dịch vụ nhận dạng tính, phiên bản (ma_mau_goc + phien_ban),
--    version cho khóa lạc quan. Không DELETE: trigger chặn xóa, quyền runtime chỉ SELECT.
--  - cot_mau: một dòng cho MỖI cột dữ liệu của tờ (chi_so_cot 0..n-1), CHECK theo vai trò. Luật nhiều dòng (đúng một HO_TEN,
--    tối đa một STT, ít nhất một DIEM, DIEM_CHU trỏ tới DIEM, đủ cột 0..n-1) kiểm trong luu_mau_bang_diem.
--  - phieu_nhan_dien.ma_mau (nullable, FK): P2 chưa ghi; chỉ dùng để biết mẫu đã được phiếu tham chiếu hay chưa.
--    Trigger chặn sửa cột_mau của mẫu đã có phiếu tham chiếu (phòng thủ chiều sâu, ngoài kiểm tra trong hàm).
--  - Ghi dữ liệu chỉ qua hai hàm SECURITY DEFINER (luu_mau_bang_diem, doi_trang_thai_mau_bang_diem) theo khuôn mẫu hiện có:
--    phiên, vai trò QUAN_TRI_VIEN, SERIALIZABLE, audit trong cùng giao dịch. kiem_tra_dinh_nghia_mau là hàm kiểm dùng chung.
--  - tieu_thu_han_muc_tac_vu: thêm thao tác FORM_TEMPLATE_TRY và FORM_TEMPLATE_ANALYZE cho QTV (giáo viên vẫn chỉ
--    RECOGNITION_UPLOAD).
--
-- ROLLBACK (chỉ tiến khi đã có mẫu): các mẫu là dữ liệu cấu hình bị phiếu tham chiếu, không xóa. Nếu chưa có mẫu và chưa có
-- phiếu nào ghi ma_mau thì có thể: DROP FUNCTION luu_mau_bang_diem, doi_trang_thai_mau_bang_diem; khôi phục hàm
-- tieu_thu_han_muc_tac_vu và CHECK gioi_han_tac_vu_hop_le của 202609130003 (DELETE FROM gioi_han_tac_vu WHERE thao_tac <>
-- 'RECOGNITION_UPLOAD' trước); ALTER TABLE phieu_nhan_dien DROP COLUMN ma_mau; DROP TABLE cot_mau, mau_bang_diem;
-- DROP TYPE "VaiTroCot", "TrangThaiMau".
BEGIN;

CREATE TYPE public."TrangThaiMau" AS ENUM ('NHAP', 'DANG_DUNG', 'NGUNG');
CREATE TYPE public."VaiTroCot" AS ENUM ('STT', 'HO_TEN', 'DIEM', 'DIEM_CHU', 'BO_QUA');

CREATE TABLE public.mau_bang_diem (
  ma_mau serial PRIMARY KEY,
  ten_mau varchar(100) NOT NULL,
  mo_ta varchar(500),
  trang_thai public."TrangThaiMau" NOT NULL DEFAULT 'NHAP',
  phien_ban integer NOT NULL DEFAULT 1,
  ma_mau_goc integer REFERENCES public.mau_bang_diem(ma_mau) ON DELETE RESTRICT ON UPDATE RESTRICT,
  chu_ky_luoi jsonb NOT NULL,
  duong_dan_anh_mau varchar(512) NOT NULL,
  ma_bam_anh_mau char(64) NOT NULL,
  nguoi_tao integer NOT NULL REFERENCES public.nguoi_dung(ma_nguoi_dung) ON DELETE RESTRICT ON UPDATE RESTRICT,
  ngay_tao timestamptz(6) NOT NULL DEFAULT now(),
  version integer NOT NULL DEFAULT 0,
  CONSTRAINT mau_ten_khong_rong CHECK (length(btrim(ten_mau)) > 0),
  CONSTRAINT mau_phien_ban_hop_le CHECK (phien_ban >= 1),
  -- Phiên bản 1 là bản gốc (không có ma_mau_goc); từ phiên bản 2 phải trỏ về bản gốc.
  CONSTRAINT mau_goc_hop_le CHECK ((ma_mau_goc IS NULL) = (phien_ban = 1) AND ma_mau_goc IS DISTINCT FROM ma_mau),
  -- Biểu thức NULL làm CHECK "đạt", nên mọi vế đều qua COALESCE/CASE để thiếu khóa thì không đạt.
  CONSTRAINT mau_chu_ky_hop_le CHECK (
    jsonb_typeof(chu_ky_luoi) = 'object'
    AND coalesce(chu_ky_luoi->'version' = '1'::jsonb, false)
    AND CASE WHEN jsonb_typeof(chu_ky_luoi->'columnWidths') = 'array'
         THEN jsonb_array_length(chu_ky_luoi->'columnWidths') BETWEEN 2 AND 64 ELSE false END
  ),
  CONSTRAINT mau_duong_dan_anh CHECK (duong_dan_anh_mau ~ '^form-templates/[0-9a-f-]{36}[.](png|jpg)$'),
  CONSTRAINT mau_ma_bam_hop_le CHECK (ma_bam_anh_mau ~ '^[0-9a-f]{64}$'),
  CONSTRAINT mau_version_hop_le CHECK (version >= 0)
);
-- Mỗi chuỗi phiên bản (bản gốc + các bản sau) có phien_ban duy nhất. Prisma không biểu diễn được chỉ mục biểu thức.
CREATE UNIQUE INDEX mau_bang_diem_chuoi_phien_ban_key
  ON public.mau_bang_diem((coalesce(ma_mau_goc, ma_mau)), phien_ban);
CREATE INDEX mau_bang_diem_ma_mau_goc_idx ON public.mau_bang_diem(ma_mau_goc) WHERE ma_mau_goc IS NOT NULL;
CREATE INDEX mau_bang_diem_nguoi_tao_idx ON public.mau_bang_diem(nguoi_tao);
CREATE INDEX mau_bang_diem_trang_thai_idx ON public.mau_bang_diem(trang_thai, ma_mau);

CREATE TABLE public.cot_mau (
  ma_mau integer NOT NULL REFERENCES public.mau_bang_diem(ma_mau) ON DELETE RESTRICT ON UPDATE RESTRICT,
  chi_so_cot integer NOT NULL,
  vai_tro public."VaiTroCot" NOT NULL,
  loai_he_so varchar(2),
  thu_tu_trong_nhom integer,
  cot_diem_di_kem integer,
  nhan_tieu_de varchar(100),
  PRIMARY KEY (ma_mau, chi_so_cot),
  CONSTRAINT cot_mau_chi_so_hop_le CHECK (chi_so_cot BETWEEN 0 AND 63),
  CONSTRAINT cot_mau_nhan_hop_le CHECK (nhan_tieu_de IS NULL OR length(btrim(nhan_tieu_de)) > 0),
  CONSTRAINT cot_mau_theo_vai_tro CHECK (
    CASE vai_tro
      WHEN 'DIEM' THEN coalesce(loai_he_so IN ('TX', 'GK', 'CK'), false)
        AND coalesce(thu_tu_trong_nhom BETWEEN 1 AND 20, false) AND cot_diem_di_kem IS NULL
      WHEN 'DIEM_CHU' THEN loai_he_so IS NULL AND thu_tu_trong_nhom IS NULL
        AND coalesce(cot_diem_di_kem BETWEEN 0 AND 63, false) AND cot_diem_di_kem <> chi_so_cot
      ELSE loai_he_so IS NULL AND thu_tu_trong_nhom IS NULL AND cot_diem_di_kem IS NULL
    END
  ),
  -- (loai_he_so, thu_tu_trong_nhom) không trùng trong một mẫu; NULL (cột không phải DIEM) không tham gia.
  CONSTRAINT cot_mau_nhom_thu_tu_key UNIQUE (ma_mau, loai_he_so, thu_tu_trong_nhom),
  -- Mỗi cột DIEM có tối đa một cột chữ đi kèm.
  CONSTRAINT cot_mau_di_kem_key UNIQUE (ma_mau, cot_diem_di_kem),
  -- DIEM_CHU phải trỏ tới một cột có thật của cùng mẫu (kiểm "là cột DIEM" trong luu_mau_bang_diem). NO ACTION + hoãn tới
  -- COMMIT để chèn/xóa theo thứ tự bất kỳ (RESTRICT không hoãn được).
  CONSTRAINT cot_mau_di_kem_fkey FOREIGN KEY (ma_mau, cot_diem_di_kem)
    REFERENCES public.cot_mau(ma_mau, chi_so_cot) ON DELETE NO ACTION ON UPDATE NO ACTION
    DEFERRABLE INITIALLY DEFERRED
);

ALTER TABLE public.phieu_nhan_dien
  ADD COLUMN ma_mau integer REFERENCES public.mau_bang_diem(ma_mau) ON DELETE RESTRICT ON UPDATE RESTRICT;
CREATE INDEX phieu_nhan_dien_ma_mau_idx ON public.phieu_nhan_dien(ma_mau) WHERE ma_mau IS NOT NULL;

-- Không hard-delete mẫu (kể cả chủ sở hữu bảng phải gỡ trigger mới xóa được).
CREATE FUNCTION public.chan_xoa_mau_bang_diem() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
BEGIN
  RAISE EXCEPTION 'TEMPLATE_DELETE_FORBIDDEN' USING ERRCODE='23514';
END $$;
CREATE TRIGGER mau_bang_diem_khong_xoa BEFORE DELETE ON public.mau_bang_diem
  FOR EACH ROW EXECUTE FUNCTION public.chan_xoa_mau_bang_diem();

-- Mẫu đã có phiếu tham chiếu thì không sửa cột mẫu (ADR-0016: "Sửa" tạo phiên bản mới).
CREATE FUNCTION public.chan_sua_cot_mau_da_dung() RETURNS trigger
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
DECLARE
  target integer;
BEGIN
  target := CASE WHEN TG_OP = 'INSERT' THEN NEW.ma_mau ELSE OLD.ma_mau END;
  IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien WHERE ma_mau = target) THEN
    RAISE EXCEPTION 'TEMPLATE_IN_USE' USING ERRCODE='23514';
  END IF;
  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END $$;
CREATE TRIGGER cot_mau_da_dung_khong_sua BEFORE INSERT OR UPDATE OR DELETE ON public.cot_mau
  FOR EACH ROW EXECUTE FUNCTION public.chan_sua_cot_mau_da_dung();

-- Hạn mức thao tác: thêm hai thao tác của QTV. RECOGNITION_UPLOAD vẫn chỉ dành cho giáo viên.
ALTER TABLE public.gioi_han_tac_vu DROP CONSTRAINT gioi_han_tac_vu_hop_le;
ALTER TABLE public.gioi_han_tac_vu ADD CONSTRAINT gioi_han_tac_vu_hop_le CHECK (
  thao_tac IN ('RECOGNITION_UPLOAD', 'FORM_TEMPLATE_TRY', 'FORM_TEMPLATE_ANALYZE') AND so_lan BETWEEN 1 AND 1001
);

CREATE OR REPLACE FUNCTION public.tieu_thu_han_muc_tac_vu(
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
  required_role public."VaiTro";
BEGIN
  IF p_thao_tac NOT IN ('RECOGNITION_UPLOAD', 'FORM_TEMPLATE_TRY', 'FORM_TEMPLATE_ANALYZE')
     OR p_gioi_han NOT BETWEEN 1 AND 1000
     OR p_cua_so_giay NOT BETWEEN 1 AND 3600 THEN
    RAISE EXCEPTION 'INVALID_OPERATION_RATE_LIMIT' USING ERRCODE='23514';
  END IF;
  required_role := CASE WHEN p_thao_tac = 'RECOGNITION_UPLOAD'
    THEN 'GIAO_VIEN'::public."VaiTro" ELSE 'QUAN_TRI_VIEN'::public."VaiTro" END;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s
  JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro=required_role
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

-- Kiểm luật hợp lệ của định nghĩa cột. p_cot: mảng đối tượng
--   {index, role, group, order, pairedWith, headerText}; phải liệt kê ĐỦ mọi cột 0..n-1 của chữ ký (BO_QUA cho cột không đọc).
-- Ném INVALID_TEMPLATE_DEFINITION (23514) kèm lý do ngắn; không chứa dữ liệu người dùng.
CREATE FUNCTION public.kiem_tra_dinh_nghia_mau(p_cot jsonb, p_so_cot integer) RETURNS void
LANGUAGE plpgsql SET search_path=pg_catalog AS $$
DECLARE
  item jsonb;
  idx integer;
  role text;
BEGIN
  IF p_cot IS NULL OR jsonb_typeof(p_cot) <> 'array' OR p_so_cot NOT BETWEEN 2 AND 64
     OR jsonb_array_length(p_cot) <> p_so_cot THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: SO_COT' USING ERRCODE='23514';
  END IF;
  FOR item IN SELECT value FROM jsonb_array_elements(p_cot) LOOP
    -- Khóa thiếu làm biểu thức NULL (IF coi NULL là sai), nên COALESCE về "không hợp lệ".
    IF coalesce(
         jsonb_typeof(item) <> 'object'
         OR jsonb_typeof(item->'index') <> 'number'
         OR (item->>'index') !~ '^[0-9]{1,2}$'
         OR jsonb_typeof(item->'role') <> 'string'
         OR (item->>'role') NOT IN ('STT','HO_TEN','DIEM','DIEM_CHU','BO_QUA')
         OR (item ? 'group' AND jsonb_typeof(item->'group') NOT IN ('null','string'))
         OR (item ? 'order' AND jsonb_typeof(item->'order') NOT IN ('null','number'))
         OR (item ? 'pairedWith' AND jsonb_typeof(item->'pairedWith') NOT IN ('null','number'))
         OR (item ? 'headerText' AND jsonb_typeof(item->'headerText') NOT IN ('null','string')),
         true) THEN
      RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: HINH_DANG' USING ERRCODE='23514';
    END IF;
    idx := (item->>'index')::integer;
    role := item->>'role';
    IF idx >= p_so_cot THEN
      RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: CHI_SO' USING ERRCODE='23514';
    END IF;
    IF role = 'DIEM' THEN
      IF (item->>'group') IS NULL OR (item->>'group') NOT IN ('TX','GK','CK')
         OR jsonb_typeof(item->'order') IS DISTINCT FROM 'number'
         OR (item->>'order') !~ '^([1-9]|1[0-9]|20)$'
         OR jsonb_typeof(item->'pairedWith') = 'number' THEN
        RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: DIEM' USING ERRCODE='23514';
      END IF;
    ELSIF role = 'DIEM_CHU' THEN
      IF jsonb_typeof(item->'group') = 'string' OR jsonb_typeof(item->'order') = 'number'
         OR jsonb_typeof(item->'pairedWith') IS DISTINCT FROM 'number'
         OR (item->>'pairedWith') !~ '^[0-9]{1,2}$' THEN
        RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: DIEM_CHU' USING ERRCODE='23514';
      END IF;
    ELSIF jsonb_typeof(item->'group') = 'string' OR jsonb_typeof(item->'order') = 'number'
          OR jsonb_typeof(item->'pairedWith') = 'number' THEN
      RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: THUA_TRUONG' USING ERRCODE='23514';
    END IF;
  END LOOP;

  -- Chỉ số 0..n-1, mỗi số đúng một lần.
  IF (SELECT count(DISTINCT (e->>'index')::integer) FROM jsonb_array_elements(p_cot) e) <> p_so_cot THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: CHI_SO_TRUNG' USING ERRCODE='23514';
  END IF;
  IF (SELECT count(*) FROM jsonb_array_elements(p_cot) e WHERE e->>'role' = 'HO_TEN') <> 1 THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: HO_TEN' USING ERRCODE='23514';
  END IF;
  IF (SELECT count(*) FROM jsonb_array_elements(p_cot) e WHERE e->>'role' = 'STT') > 1 THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: STT' USING ERRCODE='23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM jsonb_array_elements(p_cot) e WHERE e->>'role' = 'DIEM') THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: KHONG_CO_DIEM' USING ERRCODE='23514';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_cot) e WHERE e->>'role' = 'DIEM'
    GROUP BY e->>'group', (e->>'order')::integer HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: NHOM_THU_TU_TRUNG' USING ERRCODE='23514';
  END IF;
  -- DIEM_CHU trỏ tới một cột DIEM có thật; mỗi cột DIEM có tối đa một cột chữ.
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_cot) c
    WHERE c->>'role' = 'DIEM_CHU' AND NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(p_cot) d
      WHERE d->>'role' = 'DIEM' AND (d->>'index')::integer = (c->>'pairedWith')::integer)
  ) OR EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_cot) c WHERE c->>'role' = 'DIEM_CHU'
    GROUP BY (c->>'pairedWith')::integer HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: DIEM_CHU_DI_KEM' USING ERRCODE='23514';
  END IF;
END $$;

-- Tạo / sửa tại chỗ / tạo phiên bản mới của mẫu. Chỉ QTV; SERIALIZABLE; audit trong cùng giao dịch.
--   p_che_do = 'TAO'       : p_ma_mau NULL; cần p_chu_ky, p_duong_dan, p_ma_bam; trả mẫu NHAP.
--   p_che_do = 'SUA'       : mẫu chưa có phiếu tham chiếu; giữ ảnh và chữ ký; thay tên, mô tả và cột. NGUNG -> TEMPLATE_INACTIVE.
--   p_che_do = 'PHIEN_BAN' : dòng mới (NHAP, phien_ban + 1, ma_mau_goc = gốc), bản cũ -> NGUNG; chỉ từ bản mới nhất của chuỗi.
CREATE FUNCTION public.luu_mau_bang_diem(
  p_phien text,
  p_che_do text,
  p_ma_mau integer,
  p_expected_version integer,
  p_ten text,
  p_mo_ta text,
  p_cot jsonb,
  p_chu_ky jsonb,
  p_duong_dan text,
  p_ma_bam text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  actor_id integer;
  src public.mau_bang_diem;
  new_id integer;
  root_id integer;
  columns_count integer;
  signature jsonb;
  image_path text;
  image_hash text;
  name_text text;
  description text;
  item jsonb;
  result jsonb;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_che_do IS NULL OR p_che_do NOT IN ('TAO','SUA','PHIEN_BAN') THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: CHE_DO' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s
  JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  name_text := btrim(p_ten);
  description := nullif(btrim(coalesce(p_mo_ta, '')), '');
  IF name_text IS NULL OR length(name_text) NOT BETWEEN 1 AND 100
     OR length(description) > 500 THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: TEN' USING ERRCODE='23514';
  END IF;

  IF p_che_do = 'TAO' THEN
    IF p_ma_mau IS NOT NULL OR p_chu_ky IS NULL OR p_duong_dan IS NULL OR p_ma_bam IS NULL THEN
      RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: TAO' USING ERRCODE='23514';
    END IF;
    signature := p_chu_ky;
    image_path := p_duong_dan;
    image_hash := p_ma_bam;
  ELSE
    SELECT * INTO src FROM public.mau_bang_diem WHERE ma_mau=p_ma_mau FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'TEMPLATE_NOT_FOUND' USING ERRCODE='P0002'; END IF;
    IF p_expected_version IS NULL OR src.version <> p_expected_version THEN
      RAISE EXCEPTION 'VERSION_CONFLICT' USING ERRCODE='23514';
    END IF;
    signature := src.chu_ky_luoi;
    image_path := src.duong_dan_anh_mau;
    image_hash := src.ma_bam_anh_mau;
  END IF;

  IF jsonb_typeof(signature->'columnWidths') IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: CHU_KY' USING ERRCODE='23514';
  END IF;
  columns_count := jsonb_array_length(signature->'columnWidths');
  PERFORM public.kiem_tra_dinh_nghia_mau(p_cot, columns_count);

  IF p_che_do = 'SUA' THEN
    IF src.trang_thai = 'NGUNG' THEN
      RAISE EXCEPTION 'TEMPLATE_INACTIVE' USING ERRCODE='23514';
    END IF;
    IF EXISTS (SELECT 1 FROM public.phieu_nhan_dien WHERE ma_mau=p_ma_mau) THEN
      RAISE EXCEPTION 'TEMPLATE_IN_USE' USING ERRCODE='23514';
    END IF;
    new_id := p_ma_mau;
    DELETE FROM public.cot_mau WHERE ma_mau=new_id;
    UPDATE public.mau_bang_diem SET ten_mau=name_text, mo_ta=description, version=version+1
    WHERE ma_mau=new_id;
  ELSIF p_che_do = 'PHIEN_BAN' THEN
    root_id := coalesce(src.ma_mau_goc, src.ma_mau);
    -- Chỉ tạo phiên bản từ bản mới nhất của chuỗi.
    IF EXISTS (SELECT 1 FROM public.mau_bang_diem
               WHERE coalesce(ma_mau_goc, ma_mau)=root_id AND phien_ban > src.phien_ban) THEN
      RAISE EXCEPTION 'VERSION_CONFLICT' USING ERRCODE='23514';
    END IF;
    UPDATE public.mau_bang_diem SET trang_thai='NGUNG', version=version+1 WHERE ma_mau=src.ma_mau;
    INSERT INTO public.mau_bang_diem(
      ten_mau,mo_ta,phien_ban,ma_mau_goc,chu_ky_luoi,duong_dan_anh_mau,ma_bam_anh_mau,nguoi_tao
    ) VALUES (
      name_text,description,src.phien_ban+1,root_id,signature,image_path,image_hash,actor_id
    ) RETURNING ma_mau INTO new_id;
  ELSE
    INSERT INTO public.mau_bang_diem(
      ten_mau,mo_ta,chu_ky_luoi,duong_dan_anh_mau,ma_bam_anh_mau,nguoi_tao
    ) VALUES (
      name_text,description,signature,image_path,image_hash,actor_id
    ) RETURNING ma_mau INTO new_id;
  END IF;

  FOR item IN SELECT value FROM jsonb_array_elements(p_cot) LOOP
    INSERT INTO public.cot_mau(
      ma_mau,chi_so_cot,vai_tro,loai_he_so,thu_tu_trong_nhom,cot_diem_di_kem,nhan_tieu_de
    ) VALUES (
      new_id,
      (item->>'index')::integer,
      (item->>'role')::public."VaiTroCot",
      CASE WHEN item->>'role' = 'DIEM' THEN item->>'group' END,
      CASE WHEN item->>'role' = 'DIEM' THEN (item->>'order')::integer END,
      CASE WHEN item->>'role' = 'DIEM_CHU' THEN (item->>'pairedWith')::integer END,
      nullif(left(btrim(coalesce(item->>'headerText', '')), 100), '')
    );
  END LOOP;

  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,
      CASE p_che_do WHEN 'TAO' THEN 'FORM_TEMPLATE_CREATED'
                    WHEN 'SUA' THEN 'FORM_TEMPLATE_UPDATED'
                    ELSE 'FORM_TEMPLATE_VERSIONED' END,
      'mau_bang_diem:'||new_id::text);
  result := jsonb_build_object(
    'templateId', new_id,
    'storedObjectKey', image_path
  );
  RETURN result;
END $$;

-- Đổi trạng thái: 'DANG_DUNG' (kích hoạt, từ NHAP) hoặc 'NGUNG' (từ NHAP hoặc DANG_DUNG). Có khóa lạc quan theo version.
CREATE FUNCTION public.doi_trang_thai_mau_bang_diem(
  p_phien text,
  p_ma_mau integer,
  p_expected_version integer,
  p_trang_thai text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE
  actor_id integer;
  src public.mau_bang_diem;
BEGIN
  IF current_setting('transaction_isolation') <> 'serializable' THEN
    RAISE EXCEPTION 'SERIALIZABLE_REQUIRED' USING ERRCODE='25001';
  END IF;
  IF p_trang_thai IS NULL OR p_trang_thai NOT IN ('DANG_DUNG','NGUNG') THEN
    RAISE EXCEPTION 'INVALID_TEMPLATE_DEFINITION: TRANG_THAI' USING ERRCODE='23514';
  END IF;

  SELECT u.ma_nguoi_dung INTO actor_id
  FROM public.phien_lam_viec s
  JOIN public.nguoi_dung u USING(ma_nguoi_dung)
  WHERE s.ma_bam=p_phien AND u.trang_thai AND u.vai_tro='QUAN_TRI_VIEN'
    AND s.het_han>statement_timestamp()
    AND s.hoat_dong_cuoi>statement_timestamp()-interval '30 minutes';
  IF actor_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN' USING ERRCODE='42501';
  END IF;

  SELECT * INTO src FROM public.mau_bang_diem WHERE ma_mau=p_ma_mau FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'TEMPLATE_NOT_FOUND' USING ERRCODE='P0002'; END IF;
  IF p_expected_version IS NULL OR src.version <> p_expected_version THEN
    RAISE EXCEPTION 'VERSION_CONFLICT' USING ERRCODE='23514';
  END IF;
  -- Kích hoạt chỉ từ NHAP; mẫu đã NGUNG không bật lại (tạo phiên bản mới thay thế).
  IF p_trang_thai = 'DANG_DUNG' AND src.trang_thai <> 'NHAP' THEN
    RAISE EXCEPTION 'TEMPLATE_INACTIVE' USING ERRCODE='23514';
  END IF;
  IF p_trang_thai = 'NGUNG' AND src.trang_thai = 'NGUNG' THEN
    RAISE EXCEPTION 'TEMPLATE_INACTIVE' USING ERRCODE='23514';
  END IF;
  -- Một mẫu không được kích hoạt khi bản mới hơn của cùng chuỗi tồn tại.
  IF p_trang_thai = 'DANG_DUNG' AND EXISTS (
    SELECT 1 FROM public.mau_bang_diem
    WHERE coalesce(ma_mau_goc, ma_mau)=coalesce(src.ma_mau_goc, src.ma_mau) AND phien_ban > src.phien_ban) THEN
    RAISE EXCEPTION 'TEMPLATE_INACTIVE' USING ERRCODE='23514';
  END IF;

  UPDATE public.mau_bang_diem SET trang_thai=p_trang_thai::public."TrangThaiMau", version=version+1
  WHERE ma_mau=p_ma_mau;
  INSERT INTO public.nhat_ky_bao_mat(ma_tac_nhan,hanh_dong,doi_tuong)
    VALUES(actor_id,
      CASE p_trang_thai WHEN 'DANG_DUNG' THEN 'FORM_TEMPLATE_ACTIVATED' ELSE 'FORM_TEMPLATE_RETIRED' END,
      'mau_bang_diem:'||p_ma_mau::text);
  RETURN jsonb_build_object('templateId', p_ma_mau, 'status', p_trang_thai);
END $$;

REVOKE ALL ON TABLE public.mau_bang_diem, public.cot_mau FROM PUBLIC;
GRANT SELECT ON public.mau_bang_diem, public.cot_mau TO app_runtime;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.mau_bang_diem, public.cot_mau FROM app_runtime;
REVOKE ALL ON FUNCTION public.kiem_tra_dinh_nghia_mau(jsonb,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.luu_mau_bang_diem(text,text,integer,integer,text,text,jsonb,jsonb,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.luu_mau_bang_diem(text,text,integer,integer,text,text,jsonb,jsonb,text,text) TO app_runtime;
REVOKE ALL ON FUNCTION public.doi_trang_thai_mau_bang_diem(text,integer,integer,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.doi_trang_thai_mau_bang_diem(text,integer,integer,text) TO app_runtime;

COMMIT;
