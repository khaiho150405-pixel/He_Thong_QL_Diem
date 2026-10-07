/**
 * Phụ trợ cho evaluate_pages.py (BE-21/22): chạy bộ ghép dòng THẬT của API trên kết quả nhận dạng đã lưu.
 *
 *   pnpm exec tsx scripts/recognition/evaluate_matching.ts <match-input.json>
 *
 * Đầu vào: { rosters: { S01: [họ tên theo thứ tự giấy...] }, pages: [{ key, sheet, rows }] }. Đầu ra (stdout): JSON mảng
 * { key, ok, reason?, matches: [{ rowIndex, paperIndex, level }] }. Họ tên chỉ nằm trong tệp đầu vào cục bộ, không in ra.
 */
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
}

const input = JSON.parse(readFileSync(process.argv[2]!, "utf8")) as {
  rosters: Record<string, string[]>;
  pages: Array<{ key: string; sheet: string; rows: Row[] }>;
};
const output = input.pages.map((page) => {
  const names = input.rosters[page.sheet]!;
  const students = names.map((name, index) => ({
    ma_hoc_sinh: index + 1,
    ma_lop: 1,
    ho_ten: name,
    dang_theo_hoc: true,
  }));
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
      sttValue: null,
      sttConfidence: null,
      nameRaw: row.nameRaw,
      nameConfidence: null,
      hasGradeInk: !row.numeric.blank || !row.written.blank,
      hasNameInk: !row.nameBlank,
    })),
    roster,
  );
  if (!result.ok)
    return { key: page.key, ok: false, reason: result.reason, matches: [] };
  return {
    key: page.key,
    ok: true,
    matches: result.matches.map((m) => ({
      rowIndex: m.rowIndex,
      paperIndex: m.studentId - 1,
      level: m.matchLevel,
    })),
  };
});
process.stdout.write(JSON.stringify(output));
