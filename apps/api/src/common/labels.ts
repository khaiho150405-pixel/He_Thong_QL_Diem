const classificationLabels: Record<string, string> = {
  TOT: "Tốt",
  CHUA_DU_MON: "Chưa đủ môn để xếp mức",
  DIEM_TU_8: "Từ 8,0",
  DIEM_6_5: "6,5 – 7,9",
  DIEM_5: "5,0 – 6,4",
  DIEM_DUOI_5: "Dưới 5,0",
  GIOI: "Giỏi",
  KHA: "Khá",
  TRUNG_BINH: "Đạt",
  YEU: "Chưa đạt",
  KEM: "Kém",
  DAT: "Đạt",
  CHUA_DAT: "Chưa đạt",
  KHONG_DAT: "Chưa đạt",
  CHUA_CONG_BO: "Chưa công bố",
};

export function classificationLabel(code: string | null | undefined): string {
  if (!code) return "";
  return classificationLabels[code.trim().toUpperCase()] ?? code;
}

export function gradebookStatusLabel(status: string): string {
  return status === "DA_CHOT" ? "Đã khóa" : "Đang nhập liệu";
}
