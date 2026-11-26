import ExcelJS from "exceljs";
import { classificationLabel } from "../../../common/labels.js";
import { numberByClass } from "../../../common/student-order.js";
import { safeCell } from "./cells.js";
import type {
  StatisticsGroup,
  YearStatistics,
  YearStudentRow,
  YearSubjectRow,
} from "./year-port.js";

const HEADER_FILL: ExcelJS.Fill = {
  type: "pattern",
  pattern: "solid",
  fgColor: { argb: "FF176B59" },
};

function header(sheet: ExcelJS.Worksheet, values: string[]) {
  const row = sheet.addRow(values);
  row.font = { bold: true, color: { argb: "FFFFFFFF" } };
  row.fill = HEADER_FILL;
}

function sheetName(base: string, used: Set<string>) {
  const clean =
    base
      .replace(/[[\]:*?/\\']/g, " ")
      .trim()
      .slice(0, 28) || "Lop";
  let name = clean;
  for (let index = 2; used.has(name.toLowerCase()); index++)
    name = `${clean} ${index}`;
  used.add(name.toLowerCase());
  return name;
}

function vietnameseDate(iso: string) {
  const [year, month, day] = iso.split("-");
  return `${day}/${month}/${year}`;
}

function result(row: YearSubjectRow | undefined) {
  if (!row) return null;
  if (row.passFail)
    return row.classification ? classificationLabel(row.classification) : null;
  return row.finalScore === null ? null : Number(row.finalScore);
}

function componentText(row: YearSubjectRow) {
  return row.components
    .map((item) => {
      const value = item.exempt
        ? "Miễn"
        : item.value === null
          ? "-"
          : row.passFail
            ? item.value === "10.0"
              ? "Đạt"
              : "Không đạt"
            : item.value;
      return `${item.name}: ${value}`;
    })
    .join("; ");
}

function groupCells(kind: string, group: StatisticsGroup) {
  return [
    kind,
    safeCell(group.label),
    group.students,
    group.average === null ? null : Number(group.average),
    group.fromEight,
    group.fromSixHalf,
    group.fromFive,
    group.belowFive,
    group.passed,
    group.failed,
    group.levels?.TOT ?? null,
    group.levels?.KHA ?? null,
    group.levels?.DAT ?? null,
    group.levels?.CHUA_DAT ?? null,
    group.levels?.CHUA_DU_MON ?? null,
  ];
}

export async function yearWorkbook(input: {
  statistics: YearStatistics;
  term: number;
  students: YearStudentRow[];
  subjects: YearSubjectRow[];
  exportedAt: Date;
}) {
  const { statistics, students, subjects } = input;
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "Hệ thống Quản lý Điểm";
  workbook.created = input.exportedAt;
  const used = new Set<string>(["thong tin", "thong ke", "chi tiet diem"]);

  const info = workbook.addWorksheet("Thong tin");
  info.columns = [{ width: 24 }, { width: 48 }];
  info.addRows([
    ["Trường", safeCell(statistics.schoolName ?? "Chưa khai báo")],
    ["Năm học", safeCell(statistics.yearName)],
    ["Học kỳ", safeCell(students[0]?.termName ?? `Học kỳ ${input.term}`)],
    [
      "Nguồn dữ liệu",
      statistics.source === "BAN_CHOT"
        ? `Bản chốt phiên bản ${statistics.snapshotVersion} lúc ${statistics.snapshotAt} (UTC)`
        : "Dữ liệu hiện tại của các học kỳ đã công bố",
    ],
    ["Thời điểm xuất (UTC)", input.exportedAt.toISOString()],
  ]);

  const summary = workbook.addWorksheet("Thong ke");
  summary.columns = [
    { width: 12 },
    { width: 28 },
    ...Array.from({ length: 13 }, () => ({ width: 13 })),
  ];
  header(summary, [
    "Phạm vi",
    "Tên",
    "Số học sinh",
    "ĐTB",
    "Điểm từ 8,0",
    "6,5 – 7,9",
    "5,0 – 6,4",
    "Dưới 5,0",
    "Môn Đạt",
    "Môn Chưa đạt",
    "Mức Tốt",
    "Mức Khá",
    "Mức Đạt",
    "Mức Chưa đạt",
    "Chưa đủ môn",
  ]);
  if (statistics.total)
    summary.addRow(groupCells("Toàn trường", statistics.total));
  for (const [kind, groups] of [
    ["Khối", statistics.grades],
    ["Lớp", statistics.classes],
    ["Môn", statistics.subjects],
  ] as const)
    for (const group of groups) summary.addRow(groupCells(kind, group));

  const order = numberByClass(
    students.map((row) => ({
      ma_hoc_sinh: row.studentId,
      ma_lop: row.classId,
      ho_ten: row.studentName,
    })),
  );
  const sorted = [...students].sort(
    (a, b) =>
      a.grade - b.grade ||
      a.className.localeCompare(b.className, "vi") ||
      a.classId - b.classId ||
      (order.get(a.studentId) ?? 0) - (order.get(b.studentId) ?? 0),
  );
  const byStudent = new Map<number, Map<number, YearSubjectRow>>();
  for (const row of subjects) {
    const own = byStudent.get(row.studentId) ?? new Map();
    own.set(row.subjectId, row);
    byStudent.set(row.studentId, own);
  }
  const classes = new Map<number, YearStudentRow[]>();
  for (const row of sorted)
    classes.set(row.classId, [...(classes.get(row.classId) ?? []), row]);

  for (const members of classes.values()) {
    const first = members[0]!;
    const columns = new Map<number, string>();
    for (const member of members)
      for (const row of byStudent.get(member.studentId)?.values() ?? [])
        columns.set(row.subjectId, row.subjectName);
    const ordered = [...columns].sort((a, b) => a[1].localeCompare(b[1], "vi"));
    const sheet = workbook.addWorksheet(sheetName(first.className, used), {
      views: [{ state: "frozen", ySplit: 2 }],
    });
    sheet.columns = [
      { width: 8 },
      { width: 28 },
      { width: 14 },
      ...ordered.map(() => ({ width: 14 })),
      { width: 22 },
    ];
    sheet.addRow([
      safeCell(
        `Lớp ${first.className} · Giáo viên chủ nhiệm: ${first.homeroomTeacher}`,
      ),
    ]);
    sheet.getRow(1).font = { bold: true };
    header(sheet, [
      "STT",
      "Họ tên",
      "Ngày sinh",
      ...ordered.map(([, name]) => safeCell(name)),
      "Mức học tập",
    ]);
    for (const member of members)
      sheet.addRow([
        order.get(member.studentId) ?? null,
        safeCell(member.studentName),
        vietnameseDate(member.birthDate),
        ...ordered.map(([subjectId]) =>
          result(byStudent.get(member.studentId)?.get(subjectId)),
        ),
        classificationLabel(member.level ?? "CHUA_DU_MON"),
      ]);
  }

  const detail = workbook.addWorksheet("Chi tiet diem", {
    views: [{ state: "frozen", ySplit: 1 }],
  });
  detail.columns = [12, 28, 24, 24, 60, 12].map((width) => ({ width }));
  header(detail, [
    "Lớp",
    "Họ tên",
    "Môn",
    "Giáo viên",
    "Điểm thành phần",
    "Kết quả",
  ]);
  for (const member of sorted)
    for (const row of [
      ...(byStudent.get(member.studentId)?.values() ?? []),
    ].sort((a, b) => a.subjectName.localeCompare(b.subjectName, "vi")))
      detail.addRow([
        safeCell(member.className),
        safeCell(member.studentName),
        safeCell(row.subjectName),
        safeCell(row.teacher ?? ""),
        safeCell(componentText(row)),
        result(row),
      ]);

  return Buffer.from(await workbook.xlsx.writeBuffer());
}
