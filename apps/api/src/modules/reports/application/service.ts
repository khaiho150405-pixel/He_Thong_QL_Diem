import {
  Inject,
  Injectable,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import ExcelJS from "exceljs";
import type { Actor } from "../../authorization/application/policy.js";
import {
  gradebookAccess,
  gradebookActor,
} from "../../authorization/application/gradebook-policy.js";
import { classStudentOrder } from "../../../common/student-order.js";
import { classificationLabel } from "../../../common/labels.js";
import { SchoolService } from "../../school/application/service.js";
import { REPORT_STORE, type ReportStore } from "./port.js";

function id(value: number) {
  if (!Number.isSafeInteger(value) || value < 1 || value > 2147483647)
    throw new NotFoundException();
  return value;
}

function safeCell(value: string) {
  return /^[=+\-@]/.test(value) ? `'${value}` : value;
}

function numericCell(value: string | null | undefined) {
  return value == null ? null : Number(value);
}

@Injectable()
export class ReportsService {
  constructor(
    @Inject(REPORT_STORE) private readonly store: ReportStore,
    @Inject(SchoolService) private readonly school: SchoolService,
  ) {}

  summary(actor: Actor, gradebookId: number) {
    id(gradebookId);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.findBook(gradebookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      const summary = await tx.summary(gradebookId);
      const term = await tx.authorization.find("hoc_ky", {
        ma_hoc_ky: book.termId,
      });
      return term?.da_cong_bo
        ? summary
        : { ...summary, passed: 0, failed: 0, distribution: [] };
    });
  }

  adminOverview(actor: Actor) {
    if (actor.role !== "QUAN_TRI_VIEN") throw new ForbiddenException();
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      return tx.adminOverview();
    });
  }

  export(actor: Actor, gradebookId: number) {
    id(gradebookId);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.findBook(gradebookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      const term = await tx.authorization.find("hoc_ky", {
        ma_hoc_ky: book.termId,
      });
      const rawRows = (await tx.exportRows(gradebookId)).map((r) => ({
        ...r,
        classification: term?.da_cong_bo ? r.classification : "CHUA_CONG_BO",
      }));
      if (!rawRows.length) throw new NotFoundException();

      const order = classStudentOrder(
        rawRows.map((r) => ({
          ma_hoc_sinh: r.studentId,
          ma_lop: book.classId,
          ho_ten: r.studentName,
          dang_theo_hoc: true,
        })),
      );
      const rows = rawRows
        .map((row) => ({ row, stt: order.get(row.studentId) ?? 0 }))
        .sort((a, b) => a.stt - b.stt);

      const componentNames = [
        ...new Set(
          rows.flatMap(({ row }) => row.components.map((item) => item.name)),
        ),
      ];
      const passFail =
        (await tx.authorization.find("mon_hoc", { ma_mon: book.subjectId }))
          ?.danh_gia_dat === true;
      const gradeCell = (value: string | null | undefined) =>
        passFail
          ? value == null
            ? null
            : value === "10.0"
              ? "Đạt"
              : "Không đạt"
          : numericCell(value);
      const profile = await this.school.profile();
      const workbook = new ExcelJS.Workbook();
      workbook.creator = "Hệ thống Quản lý Điểm";
      workbook.created = new Date();
      const sheet = workbook.addWorksheet("Bang diem", {
        views: [{ state: "frozen", ySplit: 2 }],
      });
      const headers = [
        "STT",
        "Mã học sinh",
        "Họ tên",
        ...componentNames.map((name) => safeCell(name)),
        "Điểm tổng kết",
        "Xếp loại",
      ];
      sheet.columns = [
        { key: "stt", width: 8 },
        { key: "studentId", width: 15 },
        { key: "studentName", width: 28 },
        ...componentNames.map((_, index) => ({
          key: `component${index}`,
          width: 16,
        })),
        { key: "finalScore", width: 16 },
        { key: "classification", width: 18 },
      ];
      sheet.addRow([safeCell(profile.name)]);
      sheet.mergeCells(1, 1, 1, headers.length);
      sheet.getRow(1).font = { bold: true, size: 14 };
      sheet.addRow(headers);
      for (const { row, stt } of rows) {
        const components = new Map(
          row.components.map((item) => [item.name, item]),
        );
        sheet.addRow({
          stt,
          studentId: row.studentId,
          studentName: safeCell(row.studentName),
          ...Object.fromEntries(
            componentNames.map((name, index) => [
              `component${index}`,
              components.get(name)?.exempt
                ? "Miễn"
                : gradeCell(components.get(name)?.value),
            ]),
          ),
          finalScore: gradeCell(row.finalScore),
          classification: classificationLabel(row.classification),
        });
      }
      sheet.getRow(2).font = { bold: true, color: { argb: "FFFFFFFF" } };
      sheet.getRow(2).fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FF176B59" },
      };
      sheet.autoFilter = {
        from: "A2",
        to: sheet.getCell(2, sheet.columnCount).address,
      };
      const info = workbook.addWorksheet("Thong tin");
      info.addRows([
        ["Trường", safeCell(profile.name)],
        ["Lớp", safeCell(book.className)],
        ["Môn", safeCell(book.subjectName)],
        ["Học kỳ", safeCell(book.termName)],
        ["Trạng thái", book.status],
        ["Thời điểm xuất (UTC)", new Date().toISOString()],
      ]);
      const data = await workbook.xlsx.writeBuffer();
      await tx.recordExport(actor.id, gradebookId);
      return {
        bytes: Buffer.from(data),
        filename: `bang-diem-${gradebookId}.xlsx`,
      };
    });
  }
}
