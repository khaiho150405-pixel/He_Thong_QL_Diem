import { HttpException } from "@nestjs/common";

/**
 * Mã lỗi ổn định của lô nhận dạng (ADR-0016 mục 3–4). `status` là mã HTTP; envelope lỗi dùng chính `code` thay cho mã chung
 * theo status (xem BatchErrorFilter). Lỗi quyền (403) và không thấy (404 chung) dùng exception chuẩn của Nest.
 */
export const BATCH_ERRORS = {
  TOO_MANY_PAGES: 400,
  COMPONENT_NOT_MAPPABLE: 400,
  TEMPLATE_NOT_FOUND: 404,
  BATCH_NOT_FOUND: 404,
  TEMPLATE_INACTIVE: 409,
  RECOGNITION_ALREADY_PENDING: 409,
  DUPLICATE_FILE: 409,
  COLUMN_LOCKED: 409,
  GRADE_ENTRY_WINDOW_CLOSED: 409,
  GRADEBOOK_NOT_EDITABLE: 409,
  PASS_FAIL_SUBJECT_NOT_RECOGNIZABLE: 409,
  IDEMPOTENCY_MISMATCH: 409,
  BATCH_ALREADY_APPROVED: 409,
  INVALID_ROSTER_SNAPSHOT: 409,
} as const;
export type BatchErrorCode = keyof typeof BATCH_ERRORS;

const MESSAGES: Record<BatchErrorCode, string> = {
  TOO_MANY_PAGES: "Một lô nhận dạng có tối đa 4 trang.",
  COMPONENT_NOT_MAPPABLE:
    "Cột mẫu không phải cột điểm hoặc không khớp thành phần điểm đã chọn; xem lại ánh xạ.",
  TEMPLATE_NOT_FOUND: "Không tìm thấy mẫu bảng điểm.",
  BATCH_NOT_FOUND: "Không tìm thấy lô nhận dạng.",
  TEMPLATE_INACTIVE: "Mẫu bảng điểm chưa hoặc không còn được dùng.",
  RECOGNITION_ALREADY_PENDING:
    "Thành phần điểm này đang có phiếu chờ xử lý/đối chiếu; duyệt hoặc hủy phiếu đó trước.",
  DUPLICATE_FILE: "Ảnh này đã được tải lên ở một phiếu khác.",
  COLUMN_LOCKED: "Cột điểm đã chốt; không được nhận diện thêm.",
  GRADE_ENTRY_WINDOW_CLOSED:
    "Chưa đến thời gian nhập hoặc đã hết hạn do nhà trường đặt; không được nhận diện thêm.",
  GRADEBOOK_NOT_EDITABLE: "Bảng điểm đã chốt; không được nhận diện thêm.",
  PASS_FAIL_SUBJECT_NOT_RECOGNIZABLE:
    "Môn Đạt/Không đạt nhập bằng lựa chọn đánh giá; không dùng OCR điểm số.",
  IDEMPOTENCY_MISMATCH:
    "Khóa idempotency đã dùng cho một yêu cầu khác; dùng khóa mới.",
  BATCH_ALREADY_APPROVED: "Mọi phiếu của lô đã duyệt, không thể hủy.",
  INVALID_ROSTER_SNAPSHOT:
    "Sĩ số lớp vừa thay đổi; tải lại rồi gửi lại lô nhận dạng.",
};

export class BatchException extends HttpException {
  constructor(
    readonly code: BatchErrorCode,
    message: string = MESSAGES[code],
    readonly details: Record<string, unknown> | null = null,
  ) {
    super(message, BATCH_ERRORS[code]);
  }
}

export function batchError(
  code: BatchErrorCode,
  details: Record<string, unknown> | null = null,
): BatchException {
  return new BatchException(code, MESSAGES[code], details);
}

export function isBatchErrorCode(value: unknown): value is BatchErrorCode {
  return typeof value === "string" && Object.hasOwn(BATCH_ERRORS, value);
}
