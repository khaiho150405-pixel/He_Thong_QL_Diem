import { test } from "node:test";
import assert from "node:assert/strict";
import { ForbiddenException, UnauthorizedException } from "@nestjs/common";
import type { Unit } from "../src/common/store.js";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import { gradebookAccess } from "../src/modules/authorization/application/gradebook-policy.js";

test("gradebook policy requires exact assignment, rejects student/admin writes and rechecks session", async () => {
  const actor: Actor = {
    id: 7,
    username: "synthetic",
    role: "GIAO_VIEN",
    sessionHash: "a".repeat(64),
  };
  let active = true;
  // Pure policy fixture only; business transactions use PostgreSQL in integration tests.
  const tx = {
    find: async (table, where) => {
      if (table === "phien_lam_viec")
        return active
          ? {
              het_han: new Date(Date.now() + 60000),
              hoat_dong_cuoi: new Date(),
            }
          : null;
      if (table === "nguoi_dung")
        return { trang_thai: true, vai_tro: actor.role };
      if (table === "phan_cong_giang_day")
        return where.ma_giao_vien === 7 &&
          where.ma_lop === 1 &&
          where.ma_mon === 2 &&
          where.ma_hoc_ky === 3
          ? {}
          : null;
      return null;
    },
  } as Unit;
  const scope = { classId: 1, subjectId: 2, termId: 3 };
  await gradebookAccess(tx, actor, scope, true);
  for (const mismatch of [{ classId: 2 }, { subjectId: 3 }, { termId: 4 }])
    await assert.rejects(
      gradebookAccess(tx, actor, { ...scope, ...mismatch }, true),
      ForbiddenException,
    );
  actor.role = "QUAN_TRI_VIEN";
  await gradebookAccess(tx, actor, scope);
  await assert.rejects(
    gradebookAccess(tx, actor, scope, true),
    ForbiddenException,
  );
  actor.role = "HOC_SINH";
  await assert.rejects(gradebookAccess(tx, actor, scope), ForbiddenException);
  actor.role = "GIAO_VIEN";
  active = false;
  await assert.rejects(
    gradebookAccess(tx, actor, scope, true),
    UnauthorizedException,
  );
});
