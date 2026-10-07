import { test } from "node:test";
import assert from "node:assert/strict";
import { buildStudentOrderNumbers } from "../src/common/catalog.js";
import {
  classStudentOrder,
  compareStudents,
} from "../src/common/student-order.js";

test("student school and class order stay stable on the full active roster", () => {
  const orders = buildStudentOrderNumbers([
    { ma_hoc_sinh: 30, ma_lop: 2, ho_ten: "Trần Văn Bình" },
    { ma_hoc_sinh: 20, ma_lop: 1, ho_ten: "Nguyễn Văn An" },
    { ma_hoc_sinh: 10, ma_lop: 2, ho_ten: "Lê Văn An" },
    { ma_hoc_sinh: 40, ma_lop: 1, ho_ten: "Phạm Văn Cường" },
  ]);

  assert.equal(orders.school.get(20), 2);
  assert.equal(orders.byClass.get(20), 1);
  assert.equal(orders.school.get(30), 3);
  assert.equal(orders.byClass.get(30), 2);
});

const active = (ma_hoc_sinh: number, ma_lop: number, ho_ten: string) => ({
  ma_hoc_sinh,
  ma_lop,
  ho_ten,
  dang_theo_hoc: true,
});

test("class order sorts by given name with Vietnamese diacritics", () => {
  const order = classStudentOrder([
    active(1, 1, "Nguyễn Văn Đạt"),
    active(2, 1, "Lê Thị Bảo"),
    active(3, 1, "Trần Văn Ánh"),
    active(4, 1, "Phạm Văn An"),
  ]);
  assert.deepEqual(
    [4, 3, 2, 1].map((id) => order.get(id)),
    [1, 2, 3, 4],
  );
});

test("class order breaks ties by full name, then by student id", () => {
  const order = classStudentOrder([
    active(10, 1, "Trần Văn Bình"),
    active(11, 1, "Lê Văn Bình"),
    active(30, 1, "Hoàng Minh Châu"),
    active(21, 1, "Hoàng Minh Châu"),
  ]);
  // Cùng tên "Bình": họ tên đầy đủ phân định (Lê < Trần).
  assert.equal(order.get(11), 1);
  assert.equal(order.get(10), 2);
  // Trùng hoàn toàn họ tên: mã nhỏ trước.
  assert.equal(order.get(21), 3);
  assert.equal(order.get(30), 4);
});

test("inactive students have no order number and do not shift others", () => {
  const order = classStudentOrder([
    active(1, 1, "Lê Văn An"),
    { ...active(2, 1, "Lê Văn Bảo"), dang_theo_hoc: false },
    active(3, 1, "Lê Văn Cường"),
  ]);
  assert.equal(order.has(2), false);
  assert.equal(order.get(1), 1);
  assert.equal(order.get(3), 2);
});

test("classes are numbered independently from 1", () => {
  const order = classStudentOrder([
    active(1, 1, "Lê Văn Bảo"),
    active(2, 2, "Lê Văn An"),
    active(3, 2, "Lê Văn Cường"),
    active(4, 1, "Lê Văn An"),
  ]);
  assert.equal(order.get(4), 1);
  assert.equal(order.get(1), 2);
  assert.equal(order.get(2), 1);
  assert.equal(order.get(3), 2);
});

test("compareStudents tolerates missing and padded names", () => {
  assert.ok(
    compareStudents(
      { ma_hoc_sinh: 1, ho_ten: "  Lê   Văn An " },
      { ma_hoc_sinh: 2, ho_ten: "Lê Văn Bảo" },
    ) < 0,
  );
  assert.equal(
    compareStudents({ ma_hoc_sinh: 5 }, { ma_hoc_sinh: 5, ho_ten: "" }),
    0,
  );
});
