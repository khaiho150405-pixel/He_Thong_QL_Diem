import { test } from "node:test";
import assert from "node:assert/strict";
import {
  classificationLabel,
  gradebookStatusLabel,
} from "../src/common/labels.js";

test("classification labels use one vocabulary for every code", () => {
  assert.equal(classificationLabel("GIOI"), "Giỏi");
  assert.equal(classificationLabel("KHA"), "Khá");
  assert.equal(classificationLabel("TRUNG_BINH"), "Đạt");
  assert.equal(classificationLabel("DAT"), "Đạt");
  assert.equal(classificationLabel("YEU"), "Chưa đạt");
  assert.equal(classificationLabel("CHUA_DAT"), "Chưa đạt");
  assert.equal(classificationLabel("KHONG_DAT"), "Chưa đạt");
  assert.equal(classificationLabel("CHUA_CONG_BO"), "Chưa công bố");
  assert.equal(classificationLabel(" gioi "), "Giỏi");
  assert.equal(classificationLabel("CODE_LA"), "CODE_LA");
  assert.equal(classificationLabel(null), "");
});

test("gradebook status labels match the web and mobile screens", () => {
  assert.equal(gradebookStatusLabel("DA_CHOT"), "Đã khóa");
  assert.equal(gradebookStatusLabel("DANG_NHAP_LIEU"), "Đang nhập liệu");
});
