import assert from "node:assert/strict";
import { test } from "node:test";
import { BadRequestException, ConflictException } from "@nestjs/common";
import { parseYearId } from "../src/common/catalog.js";
import type { Row, Table, Unit } from "../src/common/store.js";
import { validateYear } from "../src/modules/academic-years/application/rules.js";
import {
  pickDefaultSemester,
  vietnamToday,
} from "../src/modules/timetable/domain/default-semester.js";

test("parseYearId: absent means no filter, anything but a positive int32 is a 400", () => {
  assert.equal(parseYearId(undefined), null);
  assert.equal(parseYearId("7"), 7);
  assert.equal(parseYearId("2147483647"), 2147483647);
  for (const bad of [
    "",
    "0",
    "-1",
    "01",
    "1.5",
    "abc",
    "1e3",
    " 1",
    "2147483648",
    "99999999999",
    ["1"],
    1,
    null,
  ])
    assert.throws(
      () => parseYearId(bad),
      BadRequestException,
      JSON.stringify(bad),
    );
});

// --- validateYear với Unit giả: chỉ theo dõi các lần ghi ---
function fakeUnit(years: Array<{ ma_nam_hoc: number; hien_hanh: boolean }>) {
  const writes: Array<[string, Row, Row]> = [];
  const audits: Row[] = [];
  const unit: Unit = {
    find: async () => null,
    list: async (_table: Table, where: Row) => {
      const except = (where.ma_nam_hoc as { not?: number } | undefined)?.not;
      return years.filter(
        (year) =>
          year.hien_hanh === where.hien_hanh && year.ma_nam_hoc !== except,
      );
    },
    count: async () => 0,
    create: async (table, data) => {
      if (table === "nhat_ky_bao_mat") audits.push(data);
      return data;
    },
    update: async (table, where, data) => {
      writes.push([table, where, data]);
      const target = years.find((y) => y.ma_nam_hoc === where.ma_nam_hoc);
      if (target) Object.assign(target, data);
      return where;
    },
    updateMany: async () => 0,
    remove: async () => {},
  };
  return { unit, writes, audits, years };
}

const dates = {
  ngay_bat_dau: new Date("2026-09-01"),
  ngay_ket_thuc: new Date("2027-06-01"),
};

test("switching the current year turns the old one off and audits it", async () => {
  const { unit, writes, audits, years } = fakeUnit([
    { ma_nam_hoc: 1, hien_hanh: true },
    { ma_nam_hoc: 2, hien_hanh: false },
  ]);
  await validateYear(
    unit,
    { ...dates, hien_hanh: true },
    { ma_nam_hoc: 2, hien_hanh: false },
    9,
  );
  assert.deepEqual(writes, [
    ["nam_hoc", { ma_nam_hoc: 1 }, { hien_hanh: false }],
  ]);
  assert.deepEqual(audits, [
    {
      ma_tac_nhan: 9,
      hanh_dong: "ACADEMIC_YEAR_SWITCHED",
      doi_tuong: "nam_hoc:1",
    },
  ]);
  assert.deepEqual(
    years.map((y) => y.hien_hanh),
    [false, false],
  );
});

test("creating a new current year switches too; saving the current year again changes nothing", async () => {
  const created = fakeUnit([{ ma_nam_hoc: 1, hien_hanh: true }]);
  await validateYear(created.unit, { ...dates, hien_hanh: true }, null, 9);
  assert.equal(created.writes.length, 1);
  const same = fakeUnit([{ ma_nam_hoc: 1, hien_hanh: true }]);
  await validateYear(
    same.unit,
    { ...dates, hien_hanh: true },
    { ma_nam_hoc: 1, hien_hanh: true },
    9,
  );
  assert.deepEqual(same.writes, []);
  assert.deepEqual(same.audits, []);
});

test("a non-current year is saved without touching the others", async () => {
  const unit = fakeUnit([{ ma_nam_hoc: 1, hien_hanh: true }]);
  await validateYear(unit.unit, { ...dates, hien_hanh: false }, null, 9);
  await validateYear(
    unit.unit,
    { ...dates, hien_hanh: false },
    { ma_nam_hoc: 2, hien_hanh: false },
    9,
  );
  assert.deepEqual(unit.writes, []);
});

test("turning off the only current year is refused with the Vietnamese message", async () => {
  const { unit, writes } = fakeUnit([{ ma_nam_hoc: 1, hien_hanh: true }]);
  await assert.rejects(
    validateYear(
      unit,
      { ...dates, hien_hanh: false },
      { ma_nam_hoc: 1, hien_hanh: true },
      9,
    ),
    (error) =>
      error instanceof ConflictException &&
      error.message ===
        "Phải có một năm học hiện hành; hãy bật năm khác để chuyển.",
  );
  assert.deepEqual(writes, []);
});

// --- Học kỳ mặc định của thời khóa biểu ---
const semester = (id: number, order: number, from: string, to: string) => ({
  ma_hoc_ky: id,
  thu_tu: order,
  ngay_bat_dau: new Date(from),
  ngay_ket_thuc: new Date(to),
});
const semesters = [
  semester(12, 2, "2027-01-15", "2027-05-31"),
  semester(11, 1, "2026-09-05", "2027-01-10"),
];

test("default semester is the one running today, whatever the array order", () => {
  assert.equal(pickDefaultSemester(semesters, "2026-10-17"), 11);
  assert.equal(pickDefaultSemester(semesters, "2027-03-01"), 12);
  // Ngày đầu và ngày cuối đều thuộc học kỳ.
  assert.equal(pickDefaultSemester(semesters, "2026-09-05"), 11);
  assert.equal(pickDefaultSemester(semesters, "2027-01-10"), 11);
  assert.equal(pickDefaultSemester(semesters, "2027-01-15"), 12);
  assert.equal(pickDefaultSemester(semesters, "2027-05-31"), 12);
});

test("outside every semester the first semester by order is used, as before", () => {
  for (const day of ["2026-08-01", "2027-01-12", "2027-07-01"])
    assert.equal(pickDefaultSemester(semesters, day), 11);
  assert.equal(pickDefaultSemester([], "2026-10-17"), undefined);
});

test("Vietnam's calendar day is used, not UTC's", () => {
  assert.equal(vietnamToday(new Date("2026-10-16T18:00:00Z")), "2026-10-17");
  assert.equal(vietnamToday(new Date("2026-10-16T16:59:59Z")), "2026-10-16");
});
