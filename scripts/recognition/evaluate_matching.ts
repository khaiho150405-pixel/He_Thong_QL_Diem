import { readFileSync } from "node:fs";
import { classStudentOrder } from "../../apps/api/src/common/student-order.ts";
import { matchRows } from "../../apps/api/src/modules/recognition/domain/row-matching.ts";

interface Row {
  index: number;
  struck: boolean;
  numeric: { blank: boolean };
  written: { blank: boolean };
  nameRaw: string | null;
  nameBlank: boolean;
  stt?: { value: number | null } | null;
}

const input = JSON.parse(readFileSync(process.argv[2]!, "utf8")) as {
  rosters: Record<string, string[]>;
  sttCheck?: boolean;
  struckStudentsActive?: boolean;
  pages: Array<{ key: string; sheet: string; start: number; rows: Row[] }>;
};
const groupOf = (key: string): string => {
  const [person, sheet, , source] = key.split("|");
  return `${person}|${sheet}|${source}`;
};
const struckByGroup = new Map<string, Set<number>>();
for (const page of input.pages) {
  const set = struckByGroup.get(groupOf(page.key)) ?? new Set<number>();
  for (const row of page.rows)
    if (row.struck) set.add(page.start + row.index - 2);
  struckByGroup.set(groupOf(page.key), set);
}
const output = input.pages.map((page) => {
  const names = input.rosters[page.sheet]!;
  const struckPaperIndexes =
    struckByGroup.get(groupOf(page.key)) ?? new Set<number>();
  const students = names
    .map((name, index) => ({
      ma_hoc_sinh: index + 1,
      ma_lop: 1,
      ho_ten: name,
      dang_theo_hoc:
        input.struckStudentsActive === true || !struckPaperIndexes.has(index),
    }))
    .filter((student) => student.dang_theo_hoc);
  const order = classStudentOrder(students);
  const roster = students
    .map((s) => ({
      stt: order.get(s.ma_hoc_sinh)!,
      studentId: s.ma_hoc_sinh,
      fullName: s.ho_ten,
    }))
    .sort((a, b) => a.stt - b.stt);
  const result = matchRows(
    page.rows.map((row) => ({
      rowIndex: row.index,
      struck: row.struck,
      sttValue: row.stt?.value ?? null,
      sttConfidence: null,
      nameRaw: row.nameRaw,
      nameConfidence: null,
      hasGradeInk: !row.numeric.blank || !row.written.blank,
      hasNameInk: !row.nameBlank,
    })),
    roster,
    { sttCheck: input.sttCheck === true },
  );
  if (!result.ok)
    return { key: page.key, ok: false, reason: result.reason, matches: [] };
  return {
    key: page.key,
    ok: true,
    model: result.stt.model,
    evidence: result.stt.evidence,
    matches: result.matches.map((m) => ({
      rowIndex: m.rowIndex,
      paperIndex: m.studentId - 1,
      level: m.matchLevel,
      note: m.note.startsWith("STT trên giấy")
        ? "STT_MISMATCH"
        : m.note.startsWith("Không xác nhận được STT")
          ? "STT_UNCONFIRMED"
          : m.note.startsWith("Trùng họ tên")
            ? "DUPLICATE_NAME"
            : "OTHER",
    })),
  };
});
process.stdout.write(JSON.stringify(output));
