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
import type { SchoolService } from "../src/modules/school/application/service.js";

const admin: Actor = {
  id: 1,
  username: "admin_test",
  role: "QUAN_TRI_VIEN",
  sessionHash: "a".repeat(64),
};

const fakeSchool = {
  profile: async () => ({ name: "Trường Giả Lập" }),
} as unknown as SchoolService;

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
  const store = fakeStore([
    student(50, "Trần Văn Đạt", "5.0"),
    student(40, "Lê Thị Bảo", "6.0"),
    student(31, "Phạm Văn An", "7.0"),
    student(21, "Hoàng Minh Châu", "8.0"),
    student(20, "Hoàng Minh Châu", "9.0"),
  ]);
  const { bytes } = await new ReportsService(store, fakeSchool).export(
    admin,
    9,
  );
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(bytes as unknown as ArrayBuffer);
  const sheet = workbook.getWorksheet("Bang diem")!;
  const table: Array<[number, string]> = [];
  assert.equal(sheet.getCell(1, 1).value, "Trường Giả Lập");
  assert.equal(sheet.getCell(2, 1).value, "STT");
  assert.equal(sheet.views[0]?.state, "frozen");
  assert.equal((sheet.views[0] as { ySplit?: number }).ySplit, 2);
  sheet.eachRow((row, index) => {
    if (index > 2)
      table.push([Number(row.getCell(1).value), String(row.getCell(2).value)]);
  });
  assert.deepEqual(table, [
    [1, "Phạm Văn An"],
    [2, "Lê Thị Bảo"],
    [3, "Hoàng Minh Châu"],
    [4, "Hoàng Minh Châu"],
    [5, "Trần Văn Đạt"],
  ]);
});

test("Excel export has STT, Họ tên, ĐGTX, ĐGGK, ĐGCK, ĐTB and a readable file name", async () => {
  const component = (name: string, kind: string, value: string) => ({
    name,
    coefficient: "1.00",
    value,
    kind,
  });
  const store = fakeStore([
    {
      studentId: 7,
      studentName: "Nguyễn Hải Anh",
      components: [
        component("ĐĐGtx 1", "TX", "9.0"),
        component("ĐĐGtx 2", "TX", "7.5"),
        component("ĐĐGgk", "GK", "9.8"),
        component("ĐĐGck", "CK", "8.8"),
      ],
      finalScore: "8.9",
      classification: "GIOI",
    },
  ]);
  const { bytes, filename } = await new ReportsService(
    store,
    fakeSchool,
  ).export(admin, 9);
  assert.equal(filename, "bang-diem-lop-gia-mon-gia-ky-gia.xlsx");
  const workbook = new ExcelJS.Workbook();
  await workbook.xlsx.load(bytes as unknown as ArrayBuffer);
  const sheet = workbook.getWorksheet("Bang diem")!;
  const header = (sheet.getRow(2).values as unknown[]).slice(1);
  assert.deepEqual(header, [
    "STT",
    "Họ tên",
    "ĐGTX 1",
    "ĐGTX 2",
    "ĐGGK",
    "ĐGCK",
    "ĐTB",
    "Xếp loại",
  ]);
  const first = (sheet.getRow(3).values as unknown[]).slice(1, 7);
  assert.deepEqual(first, [1, "Nguyễn Hải Anh", 9, 7.5, 9.8, 8.8]);
});
