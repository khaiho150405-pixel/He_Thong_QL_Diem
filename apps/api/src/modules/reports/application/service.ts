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

const viCollator = new Intl.Collator("vi", {
  sensitivity: "accent",
  numeric: true,
});

export function compareVietnameseNames(
  fullNameA: string,
  fullNameB: string,
): number {
  const partsA = fullNameA.trim().split(/\s+/);
  const partsB = fullNameB.trim().split(/\s+/);
  const givenA = partsA[partsA.length - 1] || "";
  const givenB = partsB[partsB.length - 1] || "";
  const cmp = viCollator.compare(givenA, givenB);
  if (cmp !== 0) return cmp;
  const restA = partsA.slice(0, -1).join(" ");
  const restB = partsB.slice(0, -1).join(" ");
  return viCollator.compare(restA, restB);
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

  adminOverview(actor: Actor) {
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
      const rawRows = await tx.exportRows(gradebookId);
      if (!rawRows.length) throw new NotFoundException();

      // Sort students according to standard Vietnamese alphabet (given name first)
      const rows = [...rawRows].sort((a, b) =>
        compareVietnameseNames(a.studentName, b.studentName),
      );

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
        { header: "STT", key: "stt", width: 8 },
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
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        if (!row) continue;
        const components = new Map(
          row.components.map((item) => [item.name, item.value]),
        );
        sheet.addRow({
          stt: i + 1,
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
