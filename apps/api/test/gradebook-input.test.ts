import { test } from "node:test";
import assert from "node:assert/strict";
import { BadRequestException } from "@nestjs/common";
import {
  gradeChanges,
  objectInput,
} from "../src/modules/gradebooks/application/service.js";
test("manual grades preserve NULL/zero and reject coercion, duplicates and mass assignment", () => {
  const change = {
    cellId: "9007199254740993",
    value: "0.0",
    reason: "Nhập giả",
  };
  assert.equal(gradeChanges([change])[0]!.value, "0.0");
  assert.equal(gradeChanges([{ ...change, value: null }])[0]!.value, null);
  for (const value of [
    "",
    " ",
    "1e1",
    "0x0",
    "8.55",
    "10.1",
    "-0.1",
    0,
    undefined,
  ])
    assert.throws(
      () => gradeChanges([{ ...change, value }]),
      BadRequestException,
    );
  assert.throws(() => gradeChanges([change, change]), BadRequestException);
  assert.throws(
    () => gradeChanges([{ ...change, role: "admin" }]),
    BadRequestException,
  );
  assert.throws(
    () => objectInput({ expectedVersion: 0, extra: true }, ["expectedVersion"]),
    BadRequestException,
  );
});
