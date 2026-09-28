import { test } from "node:test";
import assert from "node:assert/strict";
import { ForbiddenException } from "@nestjs/common";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import { TimetableService } from "../src/modules/timetable/application/service.js";
import { validateClassDaySchedule } from "../src/modules/timetable/domain/schedule-policy.js";

const input = {
  ma_lop: 1,
  ma_mon: 2,
  ma_giao_vien: 3,
  ma_hoc_ky: 4,
  thu: 2,
  tiet: 1,
};

function actor(role: Actor["role"]): Actor {
  return {
    id: role === "GIAO_VIEN" ? 3 : 9,
    username: "synthetic",
    role,
    sessionHash: "a".repeat(64),
  };
}

test("timetable mutations are restricted to administrators", async () => {
  const db = new Proxy(
    {},
    {
      get() {
        throw new Error(
          "Database must not be reached for a forbidden mutation",
        );
      },
    },
  );
  const service = new TimetableService(db as never);
  for (const role of ["GIAO_VIEN", "HOC_SINH"] as const) {
    await assert.rejects(
      service.createItem(actor(role), input),
      ForbiddenException,
    );
    await assert.rejects(
      service.updateItem(actor(role), 1, input),
      ForbiddenException,
    );
    await assert.rejects(
      service.deleteItem(actor(role), 1),
      ForbiddenException,
    );
  }
});

test("teacher and student reads are scoped by server-owned identities", async () => {
  const observedWhere: Record<string, unknown>[] = [];
  const db = {
    giao_vien: {
      findUnique: async () => ({ ma_giao_vien: 3 }),
    },
    hoc_sinh: {
      findFirst: async () => ({ ma_lop: 7 }),
    },
    nam_hoc: {
      findFirst: async () => null,
    },
    thoi_khoa_bieu: {
      findMany: async (query: { where: Record<string, unknown> }) => {
        observedWhere.push(query.where);
        return [];
      },
    },
  };
  const service = new TimetableService(db as never);
  await service.getTimetable(actor("GIAO_VIEN"), { teacherId: 999 });
  await service.getTimetable(actor("HOC_SINH"), {
    classId: 999,
    teacherId: 999,
  });
  assert.deepEqual(observedWhere[0], { ma_giao_vien: 3 });
  assert.deepEqual(observedWhere[1], { ma_lop: 7 });
});

test("class day requires variety, maximum four periods per session and consecutive doubles", () => {
  assert.doesNotThrow(() =>
    validateClassDaySchedule([
      { ma_mon: 1, tiet: 1 },
      { ma_mon: 1, tiet: 2 },
      { ma_mon: 2, tiet: 3 },
      { ma_mon: 3, tiet: 4 },
    ]),
  );
  assert.throws(() =>
    validateClassDaySchedule([
      { ma_mon: 1, tiet: 1 },
      { ma_mon: 1, tiet: 2 },
      { ma_mon: 2, tiet: 3 },
    ]),
  );
  assert.throws(() =>
    validateClassDaySchedule([
      { ma_mon: 1, tiet: 1 },
      { ma_mon: 1, tiet: 3 },
      { ma_mon: 2, tiet: 4 },
      { ma_mon: 3, tiet: 5 },
    ]),
  );
  assert.throws(() =>
    validateClassDaySchedule([
      { ma_mon: 1, tiet: 1 },
      { ma_mon: 2, tiet: 2 },
      { ma_mon: 3, tiet: 3 },
      { ma_mon: 4, tiet: 4 },
      { ma_mon: 5, tiet: 5 },
    ]),
  );
});
