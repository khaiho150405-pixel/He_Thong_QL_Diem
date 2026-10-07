import type { Row } from "./store.js";

// Nguồn duy nhất cho thứ tự học sinh trong lớp (ADR-0015): tên (từ cuối) →
// họ tên đầy đủ → ma_hoc_sinh. Mọi nơi cần STT phải dùng các hàm ở đây.
const viCollator = new Intl.Collator("vi", { sensitivity: "variant" });

export function compareStudents(first: Row, second: Row): number {
  const firstName = String(first.ho_ten ?? "").trim();
  const secondName = String(second.ho_ten ?? "").trim();
  const firstGivenName = firstName.split(/\s+/).at(-1) ?? "";
  const secondGivenName = secondName.split(/\s+/).at(-1) ?? "";
  return (
    viCollator.compare(firstGivenName, secondGivenName) ||
    viCollator.compare(firstName, secondName) ||
    Number(first.ma_hoc_sinh) - Number(second.ma_hoc_sinh)
  );
}

/** Đánh STT 1..n theo từng lớp cho các hàng đã được gọi là "đang xét". */
export function numberByClass(students: Row[]): Map<number, number> {
  const groups = new Map<number, Row[]>();
  for (const row of students) {
    const classId = Number(row.ma_lop);
    const group = groups.get(classId) ?? [];
    group.push(row);
    groups.set(classId, group);
  }
  const numbers = new Map<number, number>();
  for (const group of groups.values()) {
    group
      .sort(compareStudents)
      .forEach((row, index) => numbers.set(Number(row.ma_hoc_sinh), index + 1));
  }
  return numbers;
}

/**
 * STT trong lớp: chỉ học sinh `dang_theo_hoc`, STT bắt đầu từ 1 và độc lập
 * giữa các lớp. Học sinh đã nghỉ không có trong kết quả.
 */
export function classStudentOrder(students: Row[]): Map<number, number> {
  return numberByClass(students.filter((row) => row.dang_theo_hoc === true));
}
