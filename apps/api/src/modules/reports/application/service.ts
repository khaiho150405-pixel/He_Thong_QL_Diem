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

function slug(value: string) {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/gi, "d")
    .replace(/[^A-Za-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();
}

type ScoreKind = "TX" | "GK" | "CK";

function scoreKind(kind: string | null | undefined, name: string) {
  if (kind === "TX" || kind === "GK" || kind === "CK") return kind;
  if (/tx/i.test(name)) return "TX";
  if (/gk/i.test(name)) return "GK";
  if (/ck/i.test(name)) return "CK";
  return null;
}

function columnLabels(
  columns: Array<{ name: string; kind: ScoreKind | null }>,
) {
  const total = new Map<ScoreKind, number>();
  for (const column of columns)
    if (column.kind) total.set(column.kind, (total.get(column.kind) ?? 0) + 1);
  const seen = new Map<ScoreKind, number>();
  return columns.map((column) => {
    if (!column.kind) return safeCell(column.name);
    const order = (seen.get(column.kind) ?? 0) + 1;
    seen.set(column.kind, order);
    const base = `ĐG${column.kind}`;
    return total.get(column.kind) === 1 && column.kind !== "TX"
      ? base
      : `${base} ${order}`;
  });
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

      const columnByName = new Map<
        string,
        { name: string; kind: ScoreKind | null }
      >();
      for (const { row } of rows)
        for (const item of row.components)
          if (!columnByName.has(item.name))
            columnByName.set(item.name, {
              name: item.name,
              kind: scoreKind(item.kind, item.name),
            });
      const columns = [...columnByName.values()];
      const componentNames = columns.map((column) => column.name);
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
        "Họ tên",
        ...columnLabels(columns),
        "ĐTB",
        "Xếp loại",
      ];
      sheet.columns = [
        { key: "stt", width: 8 },
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
        filename: `bang-diem-${[book.className, book.subjectName, book.termName]
          .map(slug)
          .filter(Boolean)
          .join("-")}.xlsx`,
      };
    });
  }
}
