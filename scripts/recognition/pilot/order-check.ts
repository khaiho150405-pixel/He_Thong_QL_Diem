// Đối chiếu thứ tự in trên giấy với STT hệ thống (classStudentOrder). In vị trí, không in họ tên.
import { readFileSync } from "node:fs";
import { classStudentOrder } from "../../../apps/api/src/common/student-order.ts";

const students = JSON.parse(
  readFileSync(".local/pilot/class.json", "utf8"),
) as Array<{ stt: number; name: string }>;
const rows = students.map((s, i) => ({
  ma_hoc_sinh: i + 1,
  ma_lop: 1,
  ho_ten: s.name,
  dang_theo_hoc: true,
}));
const order = classStudentOrder(rows);
const diff = students
  .map((s, i) => ({ paper: s.stt, system: order.get(i + 1)! }))
  .filter((p) => p.paper !== p.system);
const givenEqual = (a: string, b: string) =>
  a.split(/\s+/).at(-1) === b.split(/\s+/).at(-1);
console.log(
  JSON.stringify({
    differing: diff,
    sameGivenNameAsNeighbour: diff.map((d) =>
      givenEqual(
        students[d.paper - 1]!.name,
        students[Math.max(0, d.system - 1)]!.name,
      ),
    ),
  }),
);
