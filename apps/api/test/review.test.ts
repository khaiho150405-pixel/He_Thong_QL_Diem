import assert from "node:assert/strict";
import { test } from "node:test";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import type {
  ApproveRecognitionInput,
  ReviewStore,
} from "../src/modules/review/application/port.js";
import {
  ReviewService,
  reviewDecisions,
} from "../src/modules/review/application/service.js";

const actor: Actor = {
  id: 7,
  username: "teacher_test",
  role: "GIAO_VIEN",
  sessionHash: "a".repeat(64),
};

test("review decisions preserve NULL/0.0 and reject ambiguous input", () => {
  assert.deepEqual(
    reviewDecisions([
      { rowId: "1", value: "0.0", reason: "  xác nhận ảnh  " },
      { rowId: "2", value: null, reason: "ô trống" },
    ]),
    [
      { rowId: "1", value: "0.0", reason: "xác nhận ảnh" },
      { rowId: "2", value: null, reason: "ô trống" },
    ],
  );
  for (const invalid of [
    [],
    [{ rowId: "1", value: 0, reason: "number is ambiguous" }],
    [{ rowId: "1", value: "8", reason: "missing decimal" }],
    [{ rowId: "1", value: "10.1", reason: "too high" }],
    [{ rowId: "0", value: "0.0", reason: "invalid ID" }],
    [
      { rowId: "1", value: "1.0", reason: "one" },
      { rowId: "1", value: "2.0", reason: "duplicate" },
    ],
    [{ rowId: "1", value: "1.0", reason: " ", extra: true }],
  ])
    assert.throws(() => reviewDecisions(invalid));
});

test("approval hashes the complete normalized request", async () => {
  let captured: ApproveRecognitionInput | undefined;
  const store: ReviewStore = {
    approve: async (input) => {
      captured = input;
      return {
        ticketId: input.ticketId,
        ticketVersion: 2,
        gradebookId: input.gradebookId,
        gradebookVersion: 3,
        reviewedRows: 1,
        machineMatchedRows: 1,
        humanCorrectedRows: 0,
        errorRows: 0,
        status: "DA_DUYET",
      };
    },
  };
  const result = await new ReviewService(store).approve(
    actor,
    4,
    "9",
    "approve-1",
    {
      expectedTicketVersion: 1,
      expectedGradebookVersion: 2,
      decisions: [{ rowId: "11", value: "0.0", reason: " xác nhận " }],
    },
  );
  assert.equal(result.status, "DA_DUYET");
  assert.equal(captured?.requestHash.length, 64);
  assert.deepEqual(captured?.decisions, [
    { rowId: "11", value: "0.0", reason: "xác nhận" },
  ]);
});
