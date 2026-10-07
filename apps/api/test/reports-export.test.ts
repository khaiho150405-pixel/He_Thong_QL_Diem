import assert from "node:assert/strict";
import { test } from "node:test";
import ExcelJS from "exceljs";
import type { Row, Table, Unit } from "../src/common/store.js";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import type {
  ExportRow,
  ReportStore,
  ReportUnit,
} from "../src/modules/reports/application/port.js";
import { ReportsService } from "../src/modules/reports/application/service.js";

const admin: Actor = {
  id: 1,
  username: "admin_test",
  role: "QUAN_TRI_VIEN",
  sessionHash: "a".repeat(64),
};

function fakeStore(rows: ExportRow[]): ReportStore {
  const now = Date.now();
  const authorization = {
    find: async (table: Table): Promise<Row | null> => {
      if (table === "phien_lam_viec")
        return {
          het_han: new Date(now + 3_600_000),
          hoat_dong_cuoi: new Date(now),
        };
      if (table === "nguoi_dung")
        return { trang_thai: true, vai_tro: "QUAN_TRI_VIEN" };
      if (table === "hoc_ky") return { da_cong_bo: true };
      if (table === "mon_hoc") return { danh_gia_dat: false };
      return null;
    },
  } as unknown as Unit;
  const unit: ReportUnit = {
    authorization,
    findBook: async () => ({
      id: 9,
      classId: 3,
      subjectId: 4,
      termId: 5,
      status: "DA_CHOT",
      version: 1,
      className: "Lớp giả",
      subjectName: "Môn giả",
      termName: "Kỳ giả",
    }),
    exportRows: async () => rows,
    recordExport: async () => {},
    summary: async () => {
      throw new Error("unused");
    },
    adminOverview: async () => {
      throw new Error("unused");
    },
  };
  return { run: (work) => work(unit) };
}

const student = (
  studentId: number,
  studentName: string,
  value: string,
): ExportRow => ({
  studentId,
  studentName,
  components: [{ name: "TX", coefficient: "1.00", value }],
  finalScore: value,
  classification: "KHA",
});

test("Excel export orders students by the shared class STT, including duplicate names", async () => {
  // Mã học sinh ≠ thứ tự tên; hai học sinh trùng hoàn toàn họ tên được phân định bằng mã.
  const store = fakeStore([
    student(50, "Trần Văn Đạt", "5.0"),
    student(40, "Lê Thị Bảo", "6.0"),
    student(31, "Phạm Văn An", "7.0"),
    student(21, "Hoàng Minh Châu", "8.0"),
    student(20, "Hoàng Minh Châu", "9.0"),
  ]);
  const { bytes } = await new ReportsService(store).export(admin, 9);
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(bytes as unknown as ArrayBuffer);
  const sheet = workbook.getWorksheet("Bang diem")!;
  const table: Array<[number, number]> = [];
  sheet.eachRow((row, index) => {
    if (index > 1)
      table.push([Number(row.getCell(1).value), Number(row.getCell(2).value)]);
  });
  // [STT, mã học sinh] theo thứ tự An, Bảo, Châu(20), Châu(21), Đạt.
  assert.deepEqual(table, [
    [1, 31],
    [2, 40],
    [3, 20],
    [4, 21],
    [5, 50],
  ]);
});
