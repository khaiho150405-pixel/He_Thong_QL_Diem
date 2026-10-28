import { ConflictException } from "@nestjs/common";

/** Lỗi nghiệp vụ 409 mang mã ổn định (`code`) và `details` cho envelope lỗi; ErrorFilter toàn cục đọc hai trường này. */
export class CodedException extends ConflictException {
  constructor(
    readonly code: string,
    message: string,
    readonly details: Record<string, unknown> | null = null,
  ) {
    super(message);
  }
}

/** Mã lỗi hàm SQL (RAISE EXCEPTION '<tên>') → mã API và thông báo tiếng Việt. */
const SQL_ERRORS: Array<[sql: string, code: string, message: string]> = [
  [
    "CELL_HAS_VALUE",
    "CELL_HAS_VALUE",
    "Ô đã có điểm hoặc đang chờ đối chiếu; chỉ miễn được ô còn trống.",
  ],
  ["CELL_NOT_EXEMPT", "CELL_NOT_EXEMPT", "Ô này không ở trạng thái miễn."],
  [
    "COLUMN_NOT_OPEN",
    "COLUMN_NOT_OPEN",
    "Cột điểm chưa mở, đã hết hạn hoặc đã chốt; không đặt/bỏ miễn được.",
  ],
  [
    "RECOGNITION_PENDING",
    "RECOGNITION_PENDING",
    "Cột còn phiếu nhận dạng đang xử lý hoặc chờ đối chiếu; xử lý xong trước.",
  ],
  [
    "EXEMPTION_VERSION_OR_STATE_CONFLICT",
    "VERSION_OR_STATE_CONFLICT",
    "Bảng điểm vừa thay đổi hoặc đã chốt; tải lại rồi thử lại.",
  ],
  [
    "CELL_EXEMPT",
    "CELL_EXEMPT",
    "Ô được miễn; bỏ miễn trước khi nhập điểm cho ô này.",
  ],
  [
    "ROW_STUDENT_EXEMPT",
    "ROW_STUDENT_EXEMPT",
    "Học sinh ở dòng này được miễn cột điểm; không duyệt giá trị cho dòng này.",
  ],
  [
    "STUDENT_NOT_IN_CLASS",
    "STUDENT_NOT_IN_CLASS",
    "Học sinh không thuộc lớp của bảng điểm hoặc không còn đang học.",
  ],
  [
    "TARGET_YEAR_NOT_AFTER",
    "TARGET_YEAR_NOT_AFTER",
    "Năm học đích phải bắt đầu sau khi năm học nguồn kết thúc.",
  ],
  [
    "TARGET_CLASS_WRONG_YEAR",
    "TARGET_CLASS_WRONG_YEAR",
    "Lớp đích không thuộc đúng năm học yêu cầu.",
  ],
  [
    "PROMOTION_GRADE_MISMATCH",
    "PROMOTION_GRADE_MISMATCH",
    "Lớp đích sai khối: lên lớp phải sang khối kế tiếp, lưu ban giữ nguyên khối.",
  ],
  [
    "GRADUATION_ONLY_GRADE_12",
    "GRADUATION_ONLY_GRADE_12",
    "Chỉ học sinh khối 12 mới xét tốt nghiệp.",
  ],
  [
    "TARGET_CLASS_REQUIRED",
    "TARGET_CLASS_REQUIRED",
    "Lên lớp hoặc lưu ban phải chọn lớp đích.",
  ],
  [
    "TARGET_CLASS_NOT_ALLOWED",
    "TARGET_CLASS_NOT_ALLOWED",
    "Tốt nghiệp hoặc nghỉ học không có lớp đích.",
  ],
  [
    "STUDENT_ALREADY_ENROLLED",
    "STUDENT_ALREADY_ENROLLED",
    "Học sinh đã có ghi danh trong năm học đích hoặc đã từng học lớp này.",
  ],
  [
    "ENROLLMENT_NOT_ACTIVE",
    "ENROLLMENT_NOT_ACTIVE",
    "Học sinh không đang học ở lớp được chọn.",
  ],
  [
    "DUPLICATE_STUDENT",
    "DUPLICATE_STUDENT",
    "Một học sinh xuất hiện nhiều lần trong danh sách.",
  ],
  [
    "TRANSFER_SAME_CLASS",
    "TRANSFER_SAME_CLASS",
    "Lớp đích trùng với lớp hiện tại của học sinh.",
  ],
  [
    "TRANSFER_GRADE_MISMATCH",
    "TRANSFER_GRADE_MISMATCH",
    "Chuyển lớp giữa năm chỉ trong cùng khối.",
  ],
  [
    "TRANSFER_HAS_LATER_GRADES",
    "TRANSFER_HAS_LATER_GRADES",
    "Lớp cũ đã có điểm của học sinh ở học kỳ từ ngày hiệu lực; không chuyển lớp được.",
  ],
  [
    "EFFECTIVE_DATE_OUT_OF_RANGE",
    "EFFECTIVE_DATE_OUT_OF_RANGE",
    "Ngày hiệu lực phải nằm trong năm học và sau ngày bắt đầu ghi danh hiện tại.",
  ],
  [
    "STUDENT_CLASS_VIA_ENROLLMENT",
    "STUDENT_CLASS_VIA_ENROLLMENT",
    "Đổi lớp hoặc trạng thái đang học của học sinh phải thực hiện qua ghi danh, không sửa trực tiếp ở danh mục học sinh.",
  ],
  [
    "CELL_NOT_LOCKED",
    "CELL_NOT_LOCKED",
    "Ô thuộc cột còn mở; nhập điểm thường, phiếu điều chỉnh chỉ dành cho cột đã chốt.",
  ],
  [
    "ADJUSTMENT_PENDING_EXISTS",
    "ADJUSTMENT_PENDING_EXISTS",
    "Bảng điểm đang có một phiếu điều chỉnh chờ duyệt; xử lý phiếu đó trước.",
  ],
  [
    "ADJUSTMENT_NO_CHANGE",
    "ADJUSTMENT_NO_CHANGE",
    "Phiếu không có thay đổi nào so với điểm hiện tại.",
  ],
  [
    "ADJUSTMENT_NOT_PENDING",
    "ADJUSTMENT_NOT_PENDING",
    "Phiếu điều chỉnh không còn ở trạng thái chờ duyệt.",
  ],
  [
    "ADJUSTMENT_STALE",
    "ADJUSTMENT_STALE",
    "Điểm của một ô trong phiếu đã thay đổi kể từ lúc gửi; từ chối phiếu và gửi lại.",
  ],
  ["INVALID_GRADE", "INVALID_GRADE", "Điểm phải từ 0.0 đến 10.0, bước 0.1."],
  [
    "PASS_FAIL_VALUE_REQUIRED",
    "PASS_FAIL_VALUE_REQUIRED",
    "Môn Đạt/Không đạt chỉ nhận Đạt hoặc Không đạt.",
  ],
  [
    "ADJUSTMENT_VERSION_OR_STATE_CONFLICT",
    "VERSION_OR_STATE_CONFLICT",
    "Bảng điểm hoặc phiếu vừa thay đổi; tải lại rồi thử lại.",
  ],
  [
    "SCHOOL_PROFILE_VERSION_CONFLICT",
    "SCHOOL_PROFILE_VERSION_CONFLICT",
    "Thông tin trường vừa được người khác thay đổi; tải lại rồi thử lại.",
  ],
  [
    "INVALID_SCHOOL_PROFILE",
    "INVALID_SCHOOL_PROFILE",
    "Thông tin trường không hợp lệ.",
  ],
  [
    "INVALID_LOGO_FILE",
    "INVALID_LOGO_FILE",
    "Logo phải là ảnh PNG hoặc JPEG hợp lệ, tối đa 1 MB.",
  ],
  [
    "TERM_ALREADY_PUBLISHED",
    "TERM_ALREADY_PUBLISHED",
    "Học kỳ đã công bố; không được thay đổi hoặc tính lại kết quả.",
  ],
];

/** Đọc lỗi nghiệp vụ có mã từ lỗi Prisma/PostgreSQL (tên trong thông điệp, DETAIL nếu có); null nếu không khớp. */
export function codedFailure(error: unknown): CodedException | null {
  const diagnostic =
    String(error) + JSON.stringify((error as { meta?: unknown }).meta ?? {});
  const incomplete = diagnostic.match(/(?<![A-Z_])TERM_RESULTS_INCOMPLETE/);
  if (incomplete) {
    return new CodedException(
      "TERM_RESULTS_INCOMPLETE",
      "Học kỳ còn phân công chưa đủ điều kiện công bố; xem chi tiết các mục cần xử lý.",
      { issues: issuesOf(error) },
    );
  }
  for (const [sql, code, message] of SQL_ERRORS) {
    // Lỗi theo học sinh có dạng 'MA_LOI:<ma_hoc_sinh>' → details { studentId, reason }.
    const found = new RegExp(`(?<![A-Z_])${sql}(?![A-Z_])(?::([0-9]+))?`).exec(
      diagnostic,
    );
    if (found)
      return new CodedException(
        code,
        message,
        found[1] ? { studentId: Number(found[1]), reason: code } : null,
      );
  }
  return null;
}

/** DETAIL của RAISE EXCEPTION chứa JSON các mục cần xử lý; không đọc được thì trả mảng rỗng. */
function issuesOf(error: unknown): unknown[] {
  const candidates: unknown[] = [];
  const e = error as {
    meta?: { message?: unknown; detail?: unknown };
    cause?: { detail?: unknown; originalMessage?: unknown };
    detail?: unknown;
  };
  candidates.push(e.detail, e.cause?.detail, e.meta?.detail, e.meta?.message);
  candidates.push(String(error));
  for (const text of candidates) {
    if (typeof text !== "string") continue;
    const start = text.indexOf("[{");
    const end = text.lastIndexOf("}]");
    if (start < 0 || end < start) continue;
    try {
      const parsed: unknown = JSON.parse(text.slice(start, end + 2));
      if (Array.isArray(parsed)) return parsed;
    } catch {
      /* thử nguồn khác */
    }
  }
  return [];
}
