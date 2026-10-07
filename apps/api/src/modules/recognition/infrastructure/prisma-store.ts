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
import { sqlStateOf, transaction } from "../../../common/transaction.js";
import { gradebookAccess } from "../../authorization/application/gradebook-policy.js";
import { currentActor } from "../../authorization/application/policy.js";
import type {
  CreateRecognitionTicket,
  RecognitionEvidenceRow,
  RecognitionStore,
  StoredRecognitionReceipt,
} from "../application/port.js";

@Injectable()
export class PrismaRecognitionStore implements RecognitionStore {
  constructor(
    @Inject("DATABASE") private readonly db: PrismaClient,
    @Inject(SETTINGS) private readonly settings: Settings,
  ) {}

  private async authorizeRead(
    tx: Prisma.TransactionClient,
    actor: CreateRecognitionTicket["actor"],
    gradebookId: number,
  ) {
    const authorization = unit(tx);
    await currentActor(authorization, actor);
    const row = await tx.bang_diem.findUnique({
      where: { ma_bang_diem: gradebookId },
    });
    if (!row) throw new NotFoundException();
    await gradebookAccess(authorization, actor, {
      classId: row.ma_lop,
      subjectId: row.ma_mon,
      termId: row.ma_hoc_ky,
    });
    return row;
  }

  list(actor: CreateRecognitionTicket["actor"], gradebookId: number) {
    return transaction(this.db, async (tx) => {
      await this.authorizeRead(tx, actor, gradebookId);
      const rows = await tx.phieu_nhan_dien.findMany({
        where: { ma_bang_diem: gradebookId },
        include: { ma_thanh_phan_ref: { select: { ten_thanh_phan: true } } },
        orderBy: { ma_phieu: "desc" },
        take: 20,
      });
      const counts = await tx.ket_qua_dong.groupBy({
        by: ["ma_phieu", "muc_phan_loai"],
        where: { ma_phieu: { in: rows.map((row) => row.ma_phieu) } },
        _count: { _all: true },
      });
      const levelCount = (ticket: bigint, level: string) =>
        counts.find(
          (item) => item.ma_phieu === ticket && item.muc_phan_loai === level,
        )?._count._all ?? 0;
      return rows.map((row) => ({
        greenRows: levelCount(row.ma_phieu, "XANH"),
        yellowRows: levelCount(row.ma_phieu, "VANG"),
        redRows: levelCount(row.ma_phieu, "DO"),
        ticketId: row.ma_phieu.toString(),
        gradebookId: row.ma_bang_diem,
        componentId: row.ma_thanh_phan,
        componentName: row.ma_thanh_phan_ref.ten_thanh_phan,
        declaredRows: row.so_dong_khai_bao,
        detectedRows: row.so_dong_nhan_dien,
        status: row.trang_thai,
        errorCode: row.ma_loi,
        modelVersion: row.phien_ban_mo_hinh,
        version: row.version,
        createdAt: row.ngay_tao.toISOString(),
      }));
    });
  }

  detail(
    actor: CreateRecognitionTicket["actor"],
    gradebookId: number,
    ticketId: string,
  ) {
    return transaction(this.db, async (tx) => {
      await this.authorizeRead(tx, actor, gradebookId);
      const row = await tx.phieu_nhan_dien.findFirst({
        where: { ma_phieu: BigInt(ticketId), ma_bang_diem: gradebookId },
        include: {
          ma_thanh_phan_ref: { select: { ten_thanh_phan: true } },
          ket_qua_dong_rows: {
            include: { ma_hoc_sinh_ref: { select: { ho_ten: true } } },
            orderBy: { thu_tu_dong: "asc" },
          },
        },
      });
      if (!row) return null;
      // Danh sách lớp đã chốt khi tạo phiếu: STT và họ tên tại thời điểm đó (ADR-0015).
      const roster = new Map(
        (
          await tx.danh_sach_phieu.findMany({
            where: { ma_phieu: row.ma_phieu },
          })
        ).map((entry) => [entry.ma_hoc_sinh, entry]),
      );
      const evidence: RecognitionEvidenceRow[] = row.ket_qua_dong_rows.map(
        (item) => ({
          rowId: item.ma_dong.toString(),
          order: item.thu_tu_dong,
          stt: roster.get(item.ma_hoc_sinh)?.stt ?? null,
          sttOnPaper: item.stt_giay,
          studentId: item.ma_hoc_sinh,
          studentName:
            roster.get(item.ma_hoc_sinh)?.ho_ten ?? item.ma_hoc_sinh_ref.ho_ten,
          nameRead: item.ho_ten_doc_duoc,
          matchConfidence: item.do_tin_cay_ghep?.toFixed(4) ?? null,
          matchNote: item.ghi_chu_ghep,
          numericRaw: item.raw_kenh_a,
          numericValue: item.gia_tri_kenh_a?.toFixed(1) ?? null,
          numericConfidence: item.do_tin_cay_a?.toFixed(4) ?? null,
          writtenRaw: item.raw_kenh_b,
          writtenValue: item.gia_tri_kenh_b?.toFixed(1) ?? null,
          writtenConfidence: item.do_tin_cay_b?.toFixed(4) ?? null,
          comparison: item.ket_luan_doi_chieu,
          reviewLevel: item.muc_phan_loai,
          finalValue: item.gia_tri_chot?.toFixed(1) ?? null,
          numericCropKey: item.duong_dan_anh_o_so,
          writtenCropKey: item.duong_dan_anh_o_chu,
          nameCropKey: item.duong_dan_anh_o_ten,
        }),
      );
      // Sắp theo STT hệ thống (phiếu cũ không có STT xếp cuối theo vị trí trên ảnh).
      evidence.sort(
        (a, b) =>
          (a.stt ?? Number.MAX_SAFE_INTEGER) -
            (b.stt ?? Number.MAX_SAFE_INTEGER) || a.order - b.order,
      );
      const levelCount = (level: string) =>
        row.ket_qua_dong_rows.filter((item) => item.muc_phan_loai === level)
          .length;
      return {
        ticketId: row.ma_phieu.toString(),
        gradebookId: row.ma_bang_diem,
        componentId: row.ma_thanh_phan,
        componentName: row.ma_thanh_phan_ref.ten_thanh_phan,
        declaredRows: row.so_dong_khai_bao,
        detectedRows: row.so_dong_nhan_dien,
        status: row.trang_thai,
        errorCode: row.ma_loi,
        modelVersion: row.phien_ban_mo_hinh,
        version: row.version,
        createdAt: row.ngay_tao.toISOString(),
        greenRows: levelCount("XANH"),
        yellowRows: levelCount("VANG"),
        redRows: levelCount("DO"),
        sourceObjectKey: row.duong_dan_anh_goc,
        rows: evidence,
      };
    });
  }

  authorizeUpload(
    actor: CreateRecognitionTicket["actor"],
    gradebookId: number,
    componentId: number,
  ): Promise<void> {
    return transaction(this.db, async (tx) => {
      const authorization = unit(tx);
      await currentActor(authorization, actor);
      const row = await tx.bang_diem.findUnique({
        where: { ma_bang_diem: gradebookId },
      });
      if (!row) throw new NotFoundException();
      await gradebookAccess(
        authorization,
        actor,
        {
          classId: row.ma_lop,
          subjectId: row.ma_mon,
          termId: row.ma_hoc_ky,
        },
        true,
      );
      if (row.trang_thai !== "DANG_NHAP_LIEU") throw new ConflictException();
      const component = await tx.thanh_phan_diem.findFirst({
        where: { ma_thanh_phan: componentId, ma_mon: row.ma_mon },
        select: { ma_thanh_phan: true },
      });
      if (!component) throw new NotFoundException();
      if (
        await tx.chot_cot_diem.count({
          where: { ma_bang_diem: gradebookId, ma_thanh_phan: componentId },
        })
      )
        throw new ConflictException("Cột điểm đã chốt; không nhận diện thêm.");
      if (
        (await tx.mon_hoc.findUnique({ where: { ma_mon: row.ma_mon } }))
          ?.danh_gia_dat
      )
        throw new ConflictException(
          "Môn Đạt/Không đạt nhập bằng lựa chọn đánh giá; không dùng OCR điểm số.",
        );
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

  async createTicket(
    input: CreateRecognitionTicket,
  ): Promise<StoredRecognitionReceipt> {
    try {
      return await transaction(this.db, async (tx) => {
        // Danh sách lớp được chốt vào phiếu ngay trong giao dịch tạo phiếu (ADR-0015).
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
        const rows = await tx.$queryRaw<
          Array<{ result: StoredRecognitionReceipt }>
        >`
          SELECT public.tao_phieu_nhan_dien(
            ${input.actor.sessionHash}::text,
            ${input.gradebookId}::integer,
            ${input.componentId}::integer,
            ${input.checksum}::text,
            ${input.objectKey}::text,
            ${JSON.stringify(roster)}::jsonb,
            ${input.idempotencyKey}::text,
            ${input.requestHash}::text
          ) AS result`;
        return rows[0]!.result;
      });
    } catch (error) {
      const code = (error as { code?: string }).code;
      const state = sqlStateOf(error);
      if (code === "P2010" && state === "42501") throw new ForbiddenException();
      if (code === "P2010" && ["02000", "P0002"].includes(state ?? ""))
        throw new NotFoundException();
      if (code === "P2010" && ["23505", "23514", "40001"].includes(state ?? ""))
        throw new ConflictException();
      throw error;
    }
  }
}
