import { Inject, Injectable, NotFoundException } from "@nestjs/common";
import ExcelJS from "exceljs";
import type { Actor } from "../../authorization/application/policy.js";
import {
  gradebookAccess,
  gradebookActor,
} from "../../authorization/application/gradebook-policy.js";
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
  constructor(@Inject(REPORT_STORE) private readonly store: ReportStore) {}

  summary(actor: Actor, gradebookId: number) {
    id(gradebookId);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.findBook(gradebookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      return tx.summary(gradebookId);
    });
  }

  export(actor: Actor, gradebookId: number) {
    id(gradebookId);
    return this.store.run(async (tx) => {
      await gradebookActor(tx.authorization, actor);
      const book = await tx.findBook(gradebookId);
      if (!book) throw new NotFoundException();
      await gradebookAccess(tx.authorization, actor, book);
      const rows = await tx.exportRows(gradebookId);
      if (!rows.length) throw new NotFoundException();

      const componentNames = [
        ...new Set(
          rows.flatMap((row) => row.components.map((item) => item.name)),
        ),
      ];
      const workbook = new ExcelJS.Workbook();
      workbook.creator = "Hệ thống Quản lý Điểm";
      workbook.created = new Date();
      const sheet = workbook.addWorksheet("Bang diem", {
        views: [{ state: "frozen", ySplit: 1 }],
      });
      sheet.columns = [
        { header: "Mã học sinh", key: "studentId", width: 15 },
        { header: "Họ tên", key: "studentName", width: 28 },
        ...componentNames.map((name, index) => ({
          header: safeCell(name),
          key: `component${index}`,
          width: 16,
        })),
        { header: "Điểm tổng kết", key: "finalScore", width: 16 },
        { header: "Xếp loại", key: "classification", width: 18 },
      ];
      for (const row of rows) {
        const components = new Map(
          row.components.map((item) => [item.name, item.value]),
        );
        sheet.addRow({
          studentId: row.studentId,
          studentName: safeCell(row.studentName),
          ...Object.fromEntries(
            componentNames.map((name, index) => [
              `component${index}`,
              numericCell(components.get(name)),
            ]),
          ),
          finalScore: numericCell(row.finalScore),
          classification: row.classification,
        });
      }
      sheet.getRow(1).font = { bold: true, color: { argb: "FFFFFFFF" } };
      sheet.getRow(1).fill = {
        type: "pattern",
        pattern: "solid",
        fgColor: { argb: "FF176B59" },
      };
      sheet.autoFilter = {
        from: "A1",
        to: sheet.getCell(1, sheet.columnCount).address,
      };
      const info = workbook.addWorksheet("Thong tin");
      info.addRows([
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
