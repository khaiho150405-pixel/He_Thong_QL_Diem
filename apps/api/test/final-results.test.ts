import assert from "node:assert/strict";
import { test } from "node:test";
import { BadRequestException } from "@nestjs/common";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import type {
  CalculateInput,
  FinalResultStore,
} from "../src/modules/final-results/application/port.js";
import {
  calculationInput,
  FinalResultsService,
  policyInput,
} from "../src/modules/final-results/application/service.js";

const actor: Actor = {
  id: 2,
  username: "teacher_test",
  role: "GIAO_VIEN",
  sessionHash: "a".repeat(64),
};

test("calculation input requires an exact version and a meaningful reason", () => {
  assert.deepEqual(
    calculationInput({ expectedVersion: 4, reason: "  Chốt kỳ  " }),
    {
      expectedVersion: 4,
      reason: "Chốt kỳ",
    },
  );
  for (const invalid of [
    {},
    { expectedVersion: -1, reason: "x" },
    { expectedVersion: 1.5, reason: "x" },
    { expectedVersion: 1, reason: " " },
    { expectedVersion: 1, reason: "x", unexpected: true },
  ])
    assert.throws(() => calculationInput(invalid), BadRequestException);
});

test("classification policy is versioned, gap-free and explicitly marks pass/fail", () => {
  const policy = policyInput({
    version: "SCHOOL-1",
    name: "Quy tắc kiểm thử",
    roundingDigits: 1,
    criteria: [
      { code: "DAT", minimum: "5.0", passing: true, order: 1 },
      { code: "CHUA_DAT", minimum: "0.0", passing: false, order: 2 },
    ],
  });
  assert.equal(policy.criteria[0]!.minimum, "5.0");
  for (const invalid of [
    { ...policy, version: "bad version" },
    { ...policy, criteria: [policy.criteria[0]] },
    {
      ...policy,
      criteria: policy.criteria.map((item) => ({ ...item, passing: true })),
    },
    {
      ...policy,
      criteria: policy.criteria.map((item) => ({ ...item, minimum: "5.0" })),
    },
  ])
    assert.throws(() => policyInput(invalid), BadRequestException);
});

test("calculation hashes the normalized request and forwards the authenticated session", async () => {
  let captured: CalculateInput | undefined;
  const store: FinalResultStore = {
    run: async (work) =>
      work({
        authorization: {
          find: async (table) =>
            table === "nguoi_dung"
              ? {
                  ma_nguoi_dung: actor.id,
                  vai_tro: actor.role,
                  trang_thai: true,
                }
              : table === "phien_lam_viec"
                ? { ma_nguoi_dung: actor.id }
                : table === "phan_cong_giang_day"
                  ? { ma_phan_cong: 1 }
                  : null,
          create: async () => ({}),
          update: async () => ({}),
          list: async () => [],
          count: async () => 0,
          remove: async () => {},
        },
        findBook: async () => ({
          id: 9,
          classId: 1,
          subjectId: 2,
          termId: 3,
          status: "DA_CHOT",
          version: 4,
        }),
        calculate: async (input) => {
          captured = input;
          return {
            gradebookId: 9,
            gradebookVersion: 4,
            weightVersion: "W-test",
            policyVersion: "DEV-2026-01",
            calculatedStudents: 0,
            skippedStudents: 0,
            results: [],
            skipped: [],
          };
        },
        list: async () => [],
        history: async () => [],
        activePolicy: async () => null,
        activatePolicy: async () => {
          throw new Error("unused");
        },
        studentResults: async () => [],
      }),
  };
  const result = await new FinalResultsService(store).calculate(
    actor,
    9,
    "calculate-1",
    { expectedVersion: 4, reason: "  Tính cuối kỳ  " },
  );
  assert.equal(result.gradebookVersion, 4);
  assert.equal(captured?.sessionHash, actor.sessionHash);
  assert.equal(captured?.reason, "Tính cuối kỳ");
  assert.equal(captured?.requestHash.length, 64);
});
