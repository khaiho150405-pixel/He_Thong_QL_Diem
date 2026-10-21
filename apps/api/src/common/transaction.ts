import { codedFailure } from "./coded-error.js";
import { ConflictException } from "@nestjs/common";
import type { PrismaClient, Prisma } from "../generated/prisma/client.js";
export function sqlStateOf(error: unknown): string | undefined {
  const e = error as {
    cause?: { originalCode?: string };
    meta?: {
      code?: string;
      driverAdapterError?: { cause?: { originalCode?: string } };
    };
  };
  return (
    e?.meta?.code ??
    e?.meta?.driverAdapterError?.cause?.originalCode ??
    e?.cause?.originalCode
  );
}
export interface TransactionOptions {
  /** Mặc định Serializable. Mức thấp hơn chỉ dành cho việc chạm phiên (không ảnh hưởng dữ liệu nghiệp vụ). */
  isolationLevel?: "Serializable" | "ReadCommitted";
}

/** Tổng số lần chạy tối đa của một giao dịch gặp lỗi tuần tự hóa (1 lần đầu + 4 lần thử lại). */
export const MAX_TRANSACTION_ATTEMPTS = 5;

/**
 * Chờ ngẫu nhiên tăng dần trước lần thử lại thứ n (n = 1..4): 20–60, 40–120, 80–240, 160–480 ms (tổng tối đa < 1 giây),
 * để các giao dịch đụng nhau không chạy lại đúng cùng lúc.
 */
export function retryDelayMs(
  retry: number,
  random: () => number = Math.random,
) {
  const low = 20 * 2 ** (retry - 1);
  return low + random() * low * 2;
}

export async function transaction<T>(
  db: PrismaClient,
  work: (tx: Prisma.TransactionClient) => Promise<T>,
  options: TransactionOptions = {},
): Promise<T> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await db.$transaction(work, {
        isolationLevel: options.isolationLevel ?? "Serializable",
        timeout: 15000,
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const sqlState = sqlStateOf(error);
      const retryable =
        code === "P2034" || ["40001", "40P01"].includes(sqlState ?? "");
      if (retryable && attempt < MAX_TRANSACTION_ATTEMPTS - 1) {
        await new Promise((resolve) =>
          setTimeout(resolve, retryDelayMs(attempt + 1)),
        );
        continue;
      }
      if (retryable)
        throw new ConflictException(
          "Dữ liệu vừa thay đổi; tải lại và thử lại.",
        );
      if (sqlState === "23514") {
        const coded = codedFailure(error);
        if (coded) throw coded;
        const diagnostic =
          String(error) +
          JSON.stringify((error as { meta?: unknown }).meta ?? {});
        const messages: Record<string, string> = {
          GRADE_ENTRY_WINDOW_CLOSED:
            "Chưa đến thời gian nhập hoặc đã hết hạn do nhà trường đặt; không được nhập/duyệt thêm.",
          DEADLINE_VERSION_CONFLICT:
            "Lịch nhập điểm vừa thay đổi; tải lại trước khi lưu.",
          INVALID_ENTRY_WINDOW:
            "Thời điểm đóng phải sau thời điểm mở và nằm trong tương lai.",
          COLUMN_LOCKED:
            "Cột điểm đã chốt; không được sửa hoặc nhận diện thêm.",
          INCOMPLETE_COLUMN:
            "Cột còn thiếu điểm bắt buộc hoặc thiếu học sinh; nhập đủ và đồng bộ sĩ số trước khi chốt.",
          PENDING_REVIEW:
            "Còn phiếu nhận diện đang xử lý hoặc chờ duyệt; xử lý xong trước khi chốt.",
          SEMESTER_WEIGHTS_LOCKED:
            "Học kỳ đã có cột/bảng điểm chốt; không thể sửa hoặc xóa hệ số.",
          TERM_RESULTS_INCOMPLETE:
            "Học kỳ còn bảng chưa chốt hoặc học sinh chưa có tổng kết; hoàn tất trước khi công bố.",
          NO_RESULTS_TO_PUBLISH: "Học kỳ chưa có kết quả để công bố.",
          TERM_ALREADY_PUBLISHED:
            "Học kỳ đã công bố; không được tính lại kết quả.",
          SUBJECT_MODE_IN_USE:
            "Môn đã có bảng điểm; không thể đổi hình thức đánh giá.",
          PASS_FAIL_VALUE_REQUIRED:
            "Môn Đạt/Không đạt chỉ nhận Đạt hoặc Không đạt.",
          // Hủy phiếu nhận dạng. VERSION_CONFLICT đứng sau mọi khóa khác chứa chuỗi này (ví dụ DEADLINE_VERSION_CONFLICT).
          TICKET_ALREADY_APPROVED: "Phiếu đã duyệt, không thể hủy.",
          RECOGNITION_ALREADY_PENDING:
            "Thành phần điểm này đang có phiếu chờ xử lý/đối chiếu; duyệt hoặc hủy phiếu đó trước.",
          INVALID_CANCEL_REQUEST: "Lý do hủy phải có từ 1 đến 200 ký tự.",
          VERSION_CONFLICT: "Phiếu vừa thay đổi, tải lại rồi thử lại.",
        };
        throw new ConflictException(
          Object.entries(messages).find(([key]) =>
            diagnostic.includes(key),
          )?.[1] ??
            "Dữ liệu vi phạm ràng buộc nghiệp vụ; kiểm tra trạng thái và các liên kết trước khi thay đổi.",
        );
      }
      if (
        sqlState === "23505" &&
        (
          String(error) +
          JSON.stringify((error as { meta?: unknown }).meta ?? {})
        ).includes("DUPLICATE_FILE")
      )
        throw new ConflictException(
          "Ảnh này đã được tải lên ở một phiếu khác.",
        );
      if (["P2002", "P2003", "P2025", "P2034"].includes(code ?? ""))
        throw new ConflictException();
      throw error;
    }
  }
}
