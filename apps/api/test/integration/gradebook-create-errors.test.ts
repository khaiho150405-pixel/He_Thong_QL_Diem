import assert from "node:assert/strict";
import { test } from "node:test";
import { ConflictException, ForbiddenException } from "@nestjs/common";
import { createGridFailure } from "../../src/modules/gradebooks/infrastructure/prisma-store.js";

test("SQL error names map to messages, everything else is left to the generic handling", () => {
  const sql = (name: string) => ({
    code: "P2010",
    meta: { code: "23514", message: `ERROR: ${name}` },
  });
  const forbidden = createGridFailure(sql("GRADEBOOK_FORBIDDEN"));
  assert.ok(forbidden instanceof ForbiddenException);
  assert.equal(
    forbidden.message,
    "Bạn chưa được phân công dạy môn này cho lớp và học kỳ đã chọn.",
  );
  assert.ok(
    createGridFailure(sql("GRADEBOOK_YEAR_MISMATCH")) instanceof
      ConflictException,
  );
  assert.ok(
    createGridFailure(sql("GRADEBOOK_EMPTY_ROSTER_OR_COMPONENTS")) instanceof
      ConflictException,
  );
  assert.equal(createGridFailure(sql("SOMETHING_ELSE")), null);
  assert.equal(createGridFailure(new Error("boom")), null);
  assert.doesNotMatch(
    String(createGridFailure(sql("GRADEBOOK_YEAR_MISMATCH"))?.message),
    /ERROR|SELECT|public\./,
  );
});
