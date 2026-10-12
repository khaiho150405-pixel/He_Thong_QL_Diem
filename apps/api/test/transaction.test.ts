import { test } from "node:test";
import assert from "node:assert/strict";
import { ConflictException } from "@nestjs/common";
import type { PrismaClient } from "../src/generated/prisma/client.js";
import { transaction, sqlStateOf } from "../src/common/transaction.js";

for (const sqlState of ["40001", "40P01"]) {
  test(`direct adapter ${sqlState} at commit retries the entire transaction`, async () => {
    let calls = 0;
    const error = {
      name: "DriverAdapterError",
      cause: { originalCode: sqlState },
    };
    const db = {
      $transaction: async (work: () => Promise<number>) => {
        calls++;
        const result = await work();
        if (calls === 1) throw error;
        return result;
      },
    } as unknown as PrismaClient;
    assert.equal(sqlStateOf(error), sqlState);
    let workCalls = 0;
    assert.equal(await transaction(db, async () => ++workCalls), 2);
    assert.equal(calls, 2);
  });
}

test("persistent serialization failure stops after three attempts with HTTP conflict", async () => {
  let calls = 0;
  const db = {
    $transaction: async () => {
      calls++;
      throw { cause: { originalCode: "40001" } };
    },
  } as unknown as PrismaClient;
  await assert.rejects(
    transaction(db, async () => 1),
    ConflictException,
  );
  assert.equal(calls, 3);
});

test("unexpected adapter errors remain visible and are not retried", async () => {
  let calls = 0;
  const error = { cause: { originalCode: "08006" } };
  const db = {
    $transaction: async () => {
      calls++;
      throw error;
    },
  } as unknown as PrismaClient;
  await assert.rejects(
    transaction(db, async () => 1),
    (e) => e === error,
  );
  assert.equal(calls, 1);
});

for (const [marker, message, sqlState] of [
  ["TICKET_ALREADY_APPROVED", "Phiếu đã duyệt, không thể hủy.", "23514"],
  ["VERSION_CONFLICT", "Phiếu vừa thay đổi, tải lại rồi thử lại.", "23514"],
  [
    "RECOGNITION_ALREADY_PENDING",
    "Thành phần điểm này đang có phiếu chờ xử lý/đối chiếu; duyệt hoặc hủy phiếu đó trước.",
    "23514",
  ],
  ["DUPLICATE_FILE", "Ảnh này đã được tải lên ở một phiếu khác.", "23505"],
] as const) {
  test(`${marker} maps to a Vietnamese conflict message`, async () => {
    const db = {
      $transaction: async () => {
        throw { code: "P2010", meta: { code: sqlState, message: marker } };
      },
    } as unknown as PrismaClient;
    await assert.rejects(
      transaction(db, async () => 1),
      (e) => e instanceof ConflictException && e.message === message,
    );
  });
}

test("a deadline version conflict keeps its own message, not the ticket one", async () => {
  const db = {
    $transaction: async () => {
      throw {
        code: "P2010",
        meta: { code: "23514", message: "DEADLINE_VERSION_CONFLICT" },
      };
    },
  } as unknown as PrismaClient;
  await assert.rejects(
    transaction(db, async () => 1),
    (e) =>
      e instanceof ConflictException &&
      e.message === "Lịch nhập điểm vừa thay đổi; tải lại trước khi lưu.",
  );
});

test("other unique violations are not rewritten as duplicate uploads", async () => {
  const error = {
    code: "P2010",
    meta: { code: "23505", message: "IDEMPOTENCY_MISMATCH" },
  };
  const db = {
    $transaction: async () => {
      throw error;
    },
  } as unknown as PrismaClient;
  await assert.rejects(
    transaction(db, async () => 1),
    (e) => e === error,
  );
});
