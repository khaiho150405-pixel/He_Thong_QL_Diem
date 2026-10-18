import { HttpException } from "@nestjs/common";

/**
 * Mã lỗi ổn định của module mẫu bảng điểm (ADR-0016 mục 4) và của luồng gọi dịch vụ nhận dạng. `status` là mã HTTP;
 * envelope lỗi dùng chính `code` thay cho mã chung theo status (xem TemplateErrorFilter).
 */
export const TEMPLATE_ERRORS = {
  INVALID_TEMPLATE_DEFINITION: 400,
  TEMPLATE_COLUMN_COUNT_MISMATCH: 400,
  TEMPLATE_NOT_FOUND: 404,
  TEMPLATE_IN_USE: 409,
  TEMPLATE_INACTIVE: 409,
  VERSION_CONFLICT: 409,
  // Dịch vụ nhận dạng từ chối ảnh (HTTP 422): phải chụp/chọn ảnh khác.
  TEMPLATE_MISMATCH: 422,
  IMAGE_UNREADABLE: 422,
  IMAGE_QUALITY_LOW: 422,
  GRID_NOT_FOUND: 422,
  NOT_A_GRADEBOOK: 422,
  SCORE_COLUMN_NOT_FOUND: 422,
  // Hạ tầng nhận dạng: có thể thử lại.
  MODEL_UNAVAILABLE: 503,
  RECOGNITION_TIMEOUT: 504,
  RECOGNITION_SERVICE_ERROR: 502,
  MALFORMED_RESPONSE: 502,
  INVALID_LAYOUT: 502,
} as const;
export type TemplateErrorCode = keyof typeof TEMPLATE_ERRORS;

export function isTemplateErrorCode(
  value: unknown,
): value is TemplateErrorCode {
  return typeof value === "string" && Object.hasOwn(TEMPLATE_ERRORS, value);
}

export class TemplateException extends HttpException {
  constructor(
    readonly code: TemplateErrorCode,
    message: string,
    readonly details: Record<string, unknown> | null = null,
  ) {
    super(message, TEMPLATE_ERRORS[code]);
  }
}

const MESSAGES: Record<TemplateErrorCode, string> = {
  INVALID_TEMPLATE_DEFINITION: "Định nghĩa mẫu bảng điểm không hợp lệ.",
  TEMPLATE_COLUMN_COUNT_MISMATCH:
    "Số cột trong định nghĩa khác số cột phân tích được từ ảnh mẫu.",
  TEMPLATE_NOT_FOUND: "Không tìm thấy mẫu bảng điểm.",
  TEMPLATE_IN_USE:
    "Mẫu đã được phiếu nhận dạng sử dụng; tạo phiên bản mới thay vì sửa tại chỗ.",
  TEMPLATE_INACTIVE: "Mẫu không ở trạng thái cho phép thao tác này.",
  VERSION_CONFLICT: "Mẫu vừa thay đổi; tải lại rồi thử lại.",
  TEMPLATE_MISMATCH:
    "Ảnh không khớp lưới của mẫu đã chọn; chọn ảnh hoặc mẫu khác.",
  IMAGE_UNREADABLE: "Không đọc được ảnh; chọn ảnh khác.",
  IMAGE_QUALITY_LOW: "Chất lượng ảnh quá thấp; chụp lại rõ hơn.",
  GRID_NOT_FOUND: "Không dò được lưới bảng điểm trong ảnh.",
  NOT_A_GRADEBOOK: "Ảnh không phải bảng điểm.",
  SCORE_COLUMN_NOT_FOUND: "Không tìm thấy cột điểm trong ảnh.",
  MODEL_UNAVAILABLE: "Dịch vụ nhận dạng tạm thời không sẵn sàng.",
  RECOGNITION_TIMEOUT: "Dịch vụ nhận dạng không trả lời kịp.",
  RECOGNITION_SERVICE_ERROR: "Dịch vụ nhận dạng gặp lỗi.",
  MALFORMED_RESPONSE: "Dịch vụ nhận dạng trả dữ liệu không hợp lệ.",
  INVALID_LAYOUT: "Dịch vụ nhận dạng từ chối bố cục mẫu.",
};

export function templateError(
  code: TemplateErrorCode,
  details: Record<string, unknown> | null = null,
  message: string = MESSAGES[code],
): TemplateException {
  return new TemplateException(code, message, details);
}
