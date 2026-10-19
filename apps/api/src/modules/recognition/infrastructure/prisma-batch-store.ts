import {
  ConflictException,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PrismaClient, Prisma } from "../../../generated/prisma/client.js";
import { SETTINGS, type Settings } from "../../../common/database.js";
import { unit } from "../../../common/store.js";
import { classStudentOrder } from "../../../common/student-order.js";
import { sqlStateOf } from "../../../common/transaction.js";
import { gradebookAccess } from "../../authorization/application/gradebook-policy.js";
import { currentActor } from "../../authorization/application/policy.js";
import {
  batchError,
  type BatchErrorCode,
} from "../application/batch-errors.js";
import type {
  BatchTicketView,
  CancelRecognitionBatch,
  CreateRecognitionBatch,
  RecognitionBatchStore,
  RecognitionBatchView,
  StoredBatchReceipt,
} from "../application/batch-port.js";

/**
 * Dịch lỗi của hàm SQL (mã nằm trong thông điệp RAISE EXCEPTION) sang mã lỗi ổn định của API. Thứ tự quan trọng: mã nào là
 * chuỗi con của mã khác phải đứng sau.
 */
const SQL_CODES: Array<[string, BatchErrorCode]> = [
  ["TOO_MANY_PAGES", "TOO_MANY_PAGES"],
  ["COMPONENT_NOT_MAPPABLE", "COMPONENT_NOT_MAPPABLE"],
  ["TEMPLATE_NOT_FOUND", "TEMPLATE_NOT_FOUND"],
  ["TEMPLATE_INACTIVE", "TEMPLATE_INACTIVE"],
  ["RECOGNITION_ALREADY_PENDING", "RECOGNITION_ALREADY_PENDING"],
  ["DUPLICATE_FILE", "DUPLICATE_FILE"],
  ["COLUMN_LOCKED", "COLUMN_LOCKED"],
  ["GRADE_ENTRY_WINDOW_CLOSED", "GRADE_ENTRY_WINDOW_CLOSED"],
  ["GRADEBOOK_NOT_EDITABLE", "GRADEBOOK_NOT_EDITABLE"],
  ["PASS_FAIL_SUBJECT_NOT_RECOGNIZABLE", "PASS_FAIL_SUBJECT_NOT_RECOGNIZABLE"],
  ["IDEMPOTENCY_MISMATCH", "IDEMPOTENCY_MISMATCH"],
  ["TICKET_ALREADY_APPROVED", "BATCH_ALREADY_APPROVED"],
  ["INVALID_ROSTER_SNAPSHOT", "INVALID_ROSTER_SNAPSHOT"],
  ["BATCH_NOT_FOUND", "BATCH_NOT_FOUND"],
];

function translate(error: unknown): unknown {
  if (error instanceof HttpException) return error;
  const diagnostic =
    String(error) +
    JSON.stringify((error as { meta?: unknown } | null)?.meta ?? {});
  const found = SQL_CODES.find(([text]) => diagnostic.includes(text));
  if (found) return batchError(found[1]);
  const code = (error as { code?: string } | null)?.code;
  const state = sqlStateOf(error);
  if (state === "42501") return new ForbiddenException();
  if (["02000", "P0002"].includes(state ?? "")) return new NotFoundException();
  if (["23505", "23514"].includes(state ?? "") || code === "P2002")
    return new ConflictException();
  return error;
}

async function run<T>(
  db: PrismaClient,
  work: (tx: Prisma.TransactionClient) => Promise<T>,
): Promise<T> {
  for (let attempt = 0; ; attempt++) {
    try {
      return await db.$transaction(work, {
        isolationLevel: "Serializable",
        timeout: 30000,
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const retryable =
        code === "P2034" ||
        ["40001", "40P01"].includes(sqlStateOf(error) ?? "");
      if (retryable && attempt < 2) continue;
      if (retryable)
        throw new ConflictException(
          "Dữ liệu vừa thay đổi; tải lại và thử lại.",
        );
      throw translate(error);
    }
  }
}

@Injectable()
export class PrismaRecognitionBatchStore implements RecognitionBatchStore {
  constructor(
    @Inject("DATABASE") private readonly db: PrismaClient,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}

  /** Đọc bảng điểm sau khi kiểm phiên và quyền; `write` chỉ giáo viên được phân công. */
  private async authorize(
    tx: Prisma.TransactionClient,
    actor: CreateRecognitionBatch["actor"],
    gradebookId: number,
    write: boolean,
  ) {
    const authorization = unit(tx);
    await currentActor(authorization, actor);
    const book = await tx.bang_diem.findUnique({
      where: { ma_bang_diem: gradebookId },
    });
    if (!book) throw new NotFoundException();
    await gradebookAccess(
      authorization,
      actor,
      { classId: book.ma_lop, subjectId: book.ma_mon, termId: book.ma_hoc_ky },
      write,
    );
    return book;
  }

  authorizeUpload(
    actor: CreateRecognitionBatch["actor"],
    gradebookId: number,
  ): Promise<void> {
    return run(this.db, async (tx) => {
      await this.authorize(tx, actor, gradebookId, true);
      const rateLimit = this.settings.uploadRateLimitPerMinute ?? 10;
      const result = await tx.$queryRaw<Array<{ allowed: boolean }>>`
        SELECT public.tieu_thu_han_muc_tac_vu(
          ${actor.sessionHash}::text,
          'RECOGNITION_UPLOAD'::text,
          ${rateLimit}::integer,
          60::integer
        ) AS allowed`;
      if (!result[0]?.allowed)
        throw new HttpException(
          "Upload rate limit exceeded",
          HttpStatus.TOO_MANY_REQUESTS,
        );
    });
  }

  create(input: CreateRecognitionBatch): Promise<StoredBatchReceipt> {
    return run(this.db, async (tx) => {
      // Danh sách lớp được chốt vào từng phiếu ngay trong giao dịch tạo lô (ADR-0015).
      const students = await tx.$queryRaw<
        Array<{ ma_hoc_sinh: number; ma_lop: number; ho_ten: string }>
      >`
        SELECT hs.ma_hoc_sinh, hs.ma_lop, hs.ho_ten
        FROM public.hoc_sinh hs JOIN public.bang_diem b ON b.ma_lop = hs.ma_lop
        WHERE b.ma_bang_diem = ${input.gradebookId}::integer AND hs.dang_theo_hoc`;
      const order = classStudentOrder(
        students.map((row) => ({ ...row, dang_theo_hoc: true })),
      );
      const roster = students
        .map((row) => ({
          stt: order.get(row.ma_hoc_sinh)!,
          studentId: row.ma_hoc_sinh,
          fullName: row.ho_ten,
        }))
        .sort((a, b) => a.stt - b.stt);
      const rows = await tx.$queryRaw<Array<{ result: StoredBatchReceipt }>>`
        SELECT public.tao_lo_nhan_dien(
          ${input.actor.sessionHash}::text,
          ${input.gradebookId}::integer,
          ${input.templateId}::integer,
          ${JSON.stringify(input.components)}::jsonb,
          ${JSON.stringify(input.pages)}::jsonb,
          ${JSON.stringify(roster)}::jsonb,
          ${input.idempotencyKey}::text,
          ${input.requestHash}::text
        ) AS result`;
      return rows[0]!.result;
    });
  }

  detail(
    actor: CreateRecognitionBatch["actor"],
    gradebookId: number,
    batchId: string,
  ): Promise<RecognitionBatchView | null> {
    return run(this.db, async (tx) => {
      // Đọc: giáo viên được phân công hoặc quản trị viên (như danh sách phiếu); học sinh bị từ chối.
      await this.authorize(tx, actor, gradebookId, false);
      const batch = await tx.lo_nhan_dien.findFirst({
        where: { ma_lo: BigInt(batchId), ma_bang_diem: gradebookId },
        include: {
          trang_rows: { orderBy: { so_trang: "asc" } },
          phieu_rows: {
            include: {
              ma_thanh_phan_ref: { select: { ten_thanh_phan: true } },
            },
            orderBy: [{ chi_so_cot_mau: "asc" }, { ma_phieu: "asc" }],
          },
        },
      });
      if (!batch) return null;
      const counts = await tx.ket_qua_dong.groupBy({
        by: ["ma_phieu", "muc_phan_loai"],
        where: {
          ma_phieu: { in: batch.phieu_rows.map((row) => row.ma_phieu) },
        },
        _count: { _all: true },
      });
      const levelCount = (ticket: bigint, level: string) =>
        counts.find(
          (item) => item.ma_phieu === ticket && item.muc_phan_loai === level,
        )?._count._all ?? 0;
      const tickets: BatchTicketView[] = batch.phieu_rows.map((row) => ({
        ticketId: row.ma_phieu.toString(),
        componentId: row.ma_thanh_phan,
        componentName: row.ma_thanh_phan_ref.ten_thanh_phan,
        templateColumnIndex: row.chi_so_cot_mau!,
        status: row.trang_thai,
        errorCode: row.ma_loi,
        version: row.version,
        greenRows: levelCount(row.ma_phieu, "XANH"),
        yellowRows: levelCount(row.ma_phieu, "VANG"),
        redRows: levelCount(row.ma_phieu, "DO"),
      }));
      return {
        batchId: batch.ma_lo.toString(),
        gradebookId: batch.ma_bang_diem,
        templateId: batch.ma_mau,
        pageCount: batch.so_trang,
        status: batch.trang_thai,
        errorCode: batch.ma_loi,
        errorPage: batch.trang_loi,
        modelVersion: batch.phien_ban_mo_hinh,
        version: batch.version,
        createdAt: batch.ngay_tao.toISOString(),
        cancelReason: batch.ly_do_huy,
        cancelledAt: batch.thoi_diem_huy?.toISOString() ?? null,
        pages: batch.trang_rows.map((page) => ({
          page: page.so_trang,
          objectKey: page.duong_dan_anh,
        })),
        tickets,
      };
    });
  }

  cancel(input: CancelRecognitionBatch): Promise<{ objectKeys: string[] }> {
    return run(this.db, async (tx) => {
      await tx.$queryRaw`
        SELECT public.huy_lo_nhan_dien(
          ${input.actor.sessionHash}::text,
          ${input.gradebookId}::integer,
          ${BigInt(input.batchId)}::bigint,
          ${input.reason}::text,
          ${input.idempotencyKey}::text,
          ${input.requestHash}::text
        ) AS result`;
      // Hàm SQL đã chặn lô không thuộc bảng điểm; đọc khóa ảnh để dọn object storage sau khi commit.
      const batch = await tx.lo_nhan_dien.findFirst({
        where: {
          ma_lo: BigInt(input.batchId),
          ma_bang_diem: input.gradebookId,
        },
        include: {
          trang_rows: { select: { duong_dan_anh: true } },
          phieu_rows: {
            select: {
              trang_thai: true,
              ket_qua_dong_rows: {
                select: {
                  duong_dan_anh_o_so: true,
                  duong_dan_anh_o_chu: true,
                  duong_dan_anh_o_ten: true,
                },
              },
            },
          },
        },
      });
      if (!batch) throw new NotFoundException();
      const cancelled = batch.phieu_rows.filter(
        (ticket) => ticket.trang_thai === "DA_HUY",
      );
      const cropKeys = cancelled.flatMap((ticket) =>
        ticket.ket_qua_dong_rows.flatMap((row) => [
          row.duong_dan_anh_o_so,
          row.duong_dan_anh_o_chu,
          row.duong_dan_anh_o_ten,
        ]),
      );
      // Ảnh trang là bằng chứng chung của mọi phiếu trong lô: chỉ xóa khi không còn phiếu nào chưa hủy (kể cả đã duyệt).
      const everyTicketCancelled = cancelled.length === batch.phieu_rows.length;
      const pageKeys = everyTicketCancelled
        ? batch.trang_rows.map((page) => page.duong_dan_anh)
        : [];
      return {
        objectKeys: [...cropKeys, ...pageKeys].filter((key): key is string =>
          Boolean(key),
        ),
      };
    });
  }
}
