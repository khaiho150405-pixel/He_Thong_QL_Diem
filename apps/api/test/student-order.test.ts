import { test } from "node:test";
import assert from "node:assert/strict";
import { buildStudentOrderNumbers } from "../src/common/catalog.js";

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
