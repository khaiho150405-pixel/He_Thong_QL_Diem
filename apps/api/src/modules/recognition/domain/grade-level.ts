export type RowLevel = "XANH" | "VANG" | "DO";

export function gradeLevelOf(
  comparison: "KHOP" | "LECH" | "MOT_KENH" | "KHONG_DOC_DUOC",
  suggestedSource: "SO" | "CHU" | null,
): RowLevel {
  if (comparison === "KHOP") return "XANH";
  return suggestedSource !== null ? "VANG" : "DO";
}
