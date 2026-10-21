import { HttpException } from "@nestjs/common";

/**
 * Mã lỗi ổn định của lịch nhập điểm theo học kỳ và khởi tạo bảng điểm hàng loạt. `status` là mã HTTP; envelope lỗi dùng
 * chính `code` thay cho mã chung theo status (xem DeadlineErrorFilter).
 */
export const DEADLINE_ERRORS = {
  NOT_IMPLEMENTED: 501,
  DEADLINE_VERSION_CONFLICT: 409,
  COLUMN_LOCKED: 409,
  INVALID_ENTRY_WINDOW: 400,
  TERM_ALREADY_PUBLISHED: 409,
} as const;
export type DeadlineErrorCode = keyof typeof DEADLINE_ERRORS;

const MESSAGES: Record<DeadlineErrorCode, string> = {
  NOT_IMPLEMENTED: "Chức năng chưa được triển khai.",
  DEADLINE_VERSION_CONFLICT:
    "Lịch nhập điểm vừa thay đổi; tải lại trước khi lưu.",
  COLUMN_LOCKED: "Lịch của loại điểm này đã qua hạn; không được sửa lại.",
  INVALID_ENTRY_WINDOW:
    "Thời điểm đóng phải sau thời điểm mở và nằm trong tương lai.",
  TERM_ALREADY_PUBLISHED:
    "Học kỳ đã công bố; không được thay đổi lịch hoặc tạo bảng điểm.",
};

export class DeadlineException extends HttpException {
  constructor(
    readonly code: DeadlineErrorCode,
    message: string = MESSAGES[code],
    readonly details: Record<string, unknown> | null = null,
  ) {
    super(message, DEADLINE_ERRORS[code]);
  }
}

export function deadlineError(code: DeadlineErrorCode): DeadlineException {
  return new DeadlineException(code);
}

/** Đọc mã lỗi nghiệp vụ trong thông điệp RAISE EXCEPTION của hàm SQL; null nếu không phải lỗi của lịch nhập. */
export function deadlineFailure(error: unknown): DeadlineException | null {
  const diagnostic =
    String(error) + JSON.stringify((error as { meta?: unknown }).meta ?? {});
  for (const code of Object.keys(DEADLINE_ERRORS) as DeadlineErrorCode[])
    if (code !== "NOT_IMPLEMENTED" && diagnostic.includes(code))
      return deadlineError(code);
  return null;
}
