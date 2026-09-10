import { test } from "node:test";
import assert from "node:assert/strict";
import {
  administrator,
  authenticated,
} from "../src/modules/authorization/application/policy.js";
import { validateInput } from "../src/common/catalog.js";
test("admin policy denies anonymous, teachers and students", () => {
  assert.throws(() => authenticated(undefined));
  for (const role of ["GIAO_VIEN", "HOC_SINH"] as const)
    assert.throws(() =>
      administrator({ id: 1, username: "fake", role, sessionHash: "fake" }),
    );
  administrator({
    id: 1,
    username: "fake",
    role: "QUAN_TRI_VIEN",
    sessionHash: "fake",
  });
});
test("catalog validation rejects mass assignment, invalid dates and coerced decimals", () => {
  const fields = {
    name: { kind: "text" as const, max: 20 },
    weight: { kind: "decimal" as const },
    date: { kind: "date" as const },
  };
  const valid = { name: "Demo", weight: "1.00", date: "2026-09-01" };
  assert.equal(validateInput(valid, fields).weight, "1.00");
  for (const invalid of [
    { ...valid, admin: true },
    { ...valid, weight: "1.001" },
    { ...valid, date: "2026-02-30" },
    { ...valid, name: " " },
    { ...valid, weight: 1 },
  ])
    assert.throws(() => validateInput(invalid, fields));
});
