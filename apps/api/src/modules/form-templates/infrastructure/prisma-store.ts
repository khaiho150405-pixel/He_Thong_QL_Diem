import {
  ConflictException,
  ForbiddenException,
  HttpException,
  Inject,
  Injectable,
} from "@nestjs/common";
import type { Prisma, PrismaClient } from "../../../generated/prisma/client.js";
import { SETTINGS, type Settings } from "../../../common/database.js";
import { unit } from "../../../common/store.js";
import { sqlStateOf } from "../../../common/transaction.js";
import { audit } from "../../audit/application/write.js";
import {
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import type { LayoutSignature } from "../../recognition/public.js";
import type {
  ColumnRole,
  GradeGroup,
  TemplateColumn,
} from "../domain/definition.js";
import { templateError } from "../application/errors.js";
import type {
  FormTemplateStore,
  SaveTemplate,
  TemplateDetail,
  TemplateForTry,
  TemplatePage,
  TemplateStatus,
  TemplateSummary,
} from "../application/port.js";

const PAGE_SIZE = 50;

type TemplateRow = Prisma.mau_bang_diemGetPayload<{
  include: { cot_rows: true };
}>;

/**
 * Dịch lỗi của hàm SQL (mã nằm trong thông điệp RAISE EXCEPTION) sang mã lỗi ổn định của API. Hàm SQL cũng chặn ở tầng DB
 * (AC-2): `INVALID_TEMPLATE_DEFINITION: SO_COT` là số cột lệch chữ ký đã lưu.
 */
function translate(error: unknown): unknown {
  if (error instanceof HttpException) return error;
  const diagnostic =
    String(error) +
    JSON.stringify((error as { meta?: unknown } | null)?.meta ?? {});
  const state = sqlStateOf(error);
  if (diagnostic.includes("INVALID_TEMPLATE_DEFINITION: SO_COT"))
    return templateError("TEMPLATE_COLUMN_COUNT_MISMATCH");
  for (const code of [
    "INVALID_TEMPLATE_DEFINITION",
    "TEMPLATE_IN_USE",
    "TEMPLATE_INACTIVE",
    "TEMPLATE_NOT_FOUND",
    "VERSION_CONFLICT",
  ] as const)
    if (diagnostic.includes(code)) return templateError(code);
  if (state === "42501") return new ForbiddenException();
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
        timeout: 15000,
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

function summary(row: TemplateRow): TemplateSummary {
  return {
    id: row.ma_mau,
    name: row.ten_mau,
    description: row.mo_ta,
    status: row.trang_thai,
    revision: row.phien_ban,
    rootTemplateId: row.ma_mau_goc,
    columnCount: row.cot_rows.length,
    gradeColumnCount: row.cot_rows.filter((column) => column.vai_tro === "DIEM")
      .length,
    version: row.version,
    createdAt: row.ngay_tao.toISOString(),
  };
}

function columnsOf(row: TemplateRow): TemplateColumn[] {
  return [...row.cot_rows]
    .sort((a, b) => a.chi_so_cot - b.chi_so_cot)
    .map((column) => ({
      index: column.chi_so_cot,
      role: column.vai_tro as ColumnRole,
      group: column.loai_he_so as GradeGroup | null,
      order: column.thu_tu_trong_nhom,
      pairedWith: column.cot_diem_di_kem,
      headerText: column.nhan_tieu_de,
    }));
}

@Injectable()
export class PrismaFormTemplateStore implements FormTemplateStore {
  constructor(
    @Inject("DATABASE") private readonly db: PrismaClient,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}

  /** Xác nhận phiên còn hiệu lực; học sinh không có quyền với bất kỳ endpoint mẫu nào. */
  private async session(
    tx: Prisma.TransactionClient,
    actor: Actor,
    administratorOnly: boolean,
  ) {
    await currentActor(unit(tx), actor);
    if (
      actor.role === "HOC_SINH" ||
      (administratorOnly && actor.role !== "QUAN_TRI_VIEN")
    )
      throw new ForbiddenException();
  }

  list(
    actor: Actor,
    cursor: number | null,
    status: TemplateStatus | null,
  ): Promise<TemplatePage> {
    return run(this.db, async (tx) => {
      await this.session(tx, actor, false);
      // Giáo viên chỉ thấy mẫu đang dùng, bất kể tham số lọc.
      const visible =
        actor.role === "GIAO_VIEN" ? ("DANG_DUNG" as const) : status;
      const rows = await tx.mau_bang_diem.findMany({
        where: {
          ma_mau: { gt: cursor ?? 0 },
          ...(visible ? { trang_thai: visible } : {}),
        },
        include: { cot_rows: true },
        orderBy: { ma_mau: "asc" },
        take: PAGE_SIZE + 1,
      });
      const page = rows.slice(0, PAGE_SIZE);
      return {
        items: page.map(summary),
        nextCursor:
          rows.length > PAGE_SIZE ? String(page[PAGE_SIZE - 1]!.ma_mau) : null,
      };
    });
  }

  detail(actor: Actor, id: number): Promise<TemplateDetail | null> {
    return run(this.db, async (tx) => {
      await this.session(tx, actor, false);
      const row = await tx.mau_bang_diem.findFirst({
        where: {
          ma_mau: id,
          ...(actor.role === "GIAO_VIEN" ? { trang_thai: "DANG_DUNG" } : {}),
        },
        include: { cot_rows: true },
      });
      return row
        ? {
            ...summary(row),
            columns: columnsOf(row),
            imageKey: row.duong_dan_anh_mau,
          }
        : null;
    });
  }

  forTry(actor: Actor, id: number): Promise<TemplateForTry | null> {
    return run(this.db, async (tx) => {
      await this.session(tx, actor, true);
      const row = await tx.mau_bang_diem.findUnique({
        where: { ma_mau: id },
        include: { cot_rows: true },
      });
      return row
        ? {
            id: row.ma_mau,
            signature: row.chu_ky_luoi as unknown as LayoutSignature,
            columns: columnsOf(row),
          }
        : null;
    });
  }

  save(input: SaveTemplate): Promise<{ templateId: number }> {
    return run(this.db, async (tx) => {
      // Ghi qua hàm SQL: phiên, vai trò QTV, luật nhiều dòng, kiểm phiếu tham chiếu, audit trong cùng giao dịch.
      const rows = await tx.$queryRaw<
        Array<{ result: { templateId: number } }>
      >`
        SELECT public.luu_mau_bang_diem(
          ${input.actor.sessionHash}::text,
          ${input.mode}::text,
          ${input.templateId}::integer,
          ${input.expectedVersion}::integer,
          ${input.name}::text,
          ${input.description}::text,
          ${JSON.stringify(input.columns)}::jsonb,
          ${input.image ? JSON.stringify(input.image.signature) : null}::jsonb,
          ${input.image?.objectKey ?? null}::text,
          ${input.image?.checksum ?? null}::text
        ) AS result`;
      return { templateId: rows[0]!.result.templateId };
    });
  }

  async setStatus(
    actor: Actor,
    id: number,
    expectedVersion: number,
    status: "DANG_DUNG" | "NGUNG",
  ): Promise<void> {
    await run(this.db, async (tx) => {
      await tx.$queryRaw`
        SELECT public.doi_trang_thai_mau_bang_diem(
          ${actor.sessionHash}::text,
          ${id}::integer,
          ${expectedVersion}::integer,
          ${status}::text
        ) AS result`;
    });
  }

  consumeRateLimit(
    actor: Actor,
    operation: "FORM_TEMPLATE_TRY" | "FORM_TEMPLATE_ANALYZE",
  ): Promise<boolean> {
    return run(this.db, async (tx) => {
      const rows = await tx.$queryRaw<Array<{ allowed: boolean }>>`
        SELECT public.tieu_thu_han_muc_tac_vu(
          ${actor.sessionHash}::text,
          ${operation}::text,
          ${this.settings.uploadRateLimitPerMinute ?? 10}::integer,
          60::integer
        ) AS allowed`;
      return rows[0]?.allowed === true;
    });
  }

  recordAudit(actor: Actor, action: string, target: string): Promise<void> {
    return run(this.db, async (tx) => {
      await this.session(tx, actor, true);
      await audit(unit(tx), actor.id, action, target);
    });
  }
}
