const classificationLabels: Record<string, string> = {
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
