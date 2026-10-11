// Mức điểm (hai kênh) của một dòng nhận dạng, suy lại từ dữ liệu đã lưu để màn hình đối chiếu giải thích được lý do.
// Không phải luật mới: chỉ phản ánh luật hợp nhất ở dịch vụ nhận dạng (ADR-0015). Phiếu cũ không lưu mức ghép riêng (matchLevel
// null) nên màn hình giữ hành vi cũ cho phần ghép; mức điểm vẫn suy được theo cùng quy tắc.
export type RowLevel = "XANH" | "VANG" | "DO";

/** Hai kênh đồng thuận → XANH; có kênh gợi ý (chỉ một kênh đủ tin cậy) → VANG; còn lại → DO. */
export function gradeLevelOf(
  comparison: "KHOP" | "LECH" | "MOT_KENH" | "KHONG_DOC_DUOC",
  suggestedSource: "SO" | "CHU" | null,
): RowLevel {
  if (comparison === "KHOP") return "XANH";
  return suggestedSource !== null ? "VANG" : "DO";
}
