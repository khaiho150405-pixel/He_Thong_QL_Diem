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
export async function transaction<T>(
  db: PrismaClient,
  work: (tx: Prisma.TransactionClient) => Promise<T>,
): Promise<T> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await db.$transaction(work, {
        isolationLevel: "Serializable",
        timeout: 15000,
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const sqlState = sqlStateOf(error);
      const retryable =
        code === "P2034" || ["40001", "40P01"].includes(sqlState ?? "");
      if (retryable && attempt < 2) continue;
      if (retryable)
        throw new ConflictException(
          "Dữ liệu vừa thay đổi; tải lại và thử lại.",
        );
      if (sqlState === "23514") {
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
        };
        throw new ConflictException(
          Object.entries(messages).find(([key]) =>
            diagnostic.includes(key),
          )?.[1] ??
            "Dữ liệu vi phạm ràng buộc nghiệp vụ; kiểm tra trạng thái và các liên kết trước khi thay đổi.",
        );
      }
      if (["P2002", "P2003", "P2025", "P2034"].includes(code ?? ""))
        throw new ConflictException();
      throw error;
    }
  }
}
