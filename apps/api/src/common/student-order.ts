import type { Row } from "./store.js";

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

export function classStudentOrder(students: Row[]): Map<number, number> {
  return numberByClass(students.filter((row) => row.dang_theo_hoc === true));
}
