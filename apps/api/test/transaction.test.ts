import { test } from "node:test";
import assert from "node:assert/strict";
import { ConflictException } from "@nestjs/common";
import type { PrismaClient } from "../src/generated/prisma/client.js";
import {
  MAX_TRANSACTION_ATTEMPTS,
  retryDelayMs,
  sqlStateOf,
  transaction,
} from "../src/common/transaction.js";

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

test("persistent serialization failure stops after five attempts with HTTP conflict", async () => {
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
  assert.equal(calls, MAX_TRANSACTION_ATTEMPTS);
  assert.equal(MAX_TRANSACTION_ATTEMPTS, 5);
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

test("retry waits grow with randomised jitter and total less than one second", () => {
  assert.equal(MAX_TRANSACTION_ATTEMPTS - 1, 4);
  const bounds = [1, 2, 3, 4].map((retry) => [
    retryDelayMs(retry, () => 0),
    retryDelayMs(retry, () => 1),
  ]);
  assert.deepEqual(bounds, [
    [20, 60],
    [40, 120],
    [80, 240],
    [160, 480],
  ]);
  assert.ok(bounds.reduce((sum, [, high]) => sum + high!, 0) < 1000);
  // Ngẫu nhiên thật sự: nhiều lần lấy mẫu không cho cùng một giá trị.
  assert.ok(
    new Set(Array.from({ length: 20 }, () => retryDelayMs(3))).size > 1,
  );
});

test("a transaction that succeeds after a few serialization failures is retried with a pause", async () => {
  let calls = 0;
  const db = {
    $transaction: async () => {
      calls++;
      if (calls < 4) throw { code: "P2034" };
      return calls;
    },
  } as unknown as PrismaClient;
  const started = Date.now();
  assert.equal(await transaction(db, async () => 0), 4);
  assert.ok(Date.now() - started >= 20 + 40 + 80 - 5);
});

test("isolation level defaults to Serializable and can be lowered explicitly", async () => {
  const seen: unknown[] = [];
  const db = {
    $transaction: async (
      _work: unknown,
      options: { isolationLevel: string },
    ) => {
      seen.push(options.isolationLevel);
      return 1;
    },
  } as unknown as PrismaClient;
  await transaction(db, async () => 0);
  await transaction(db, async () => 0, { isolationLevel: "ReadCommitted" });
  assert.deepEqual(seen, ["Serializable", "ReadCommitted"]);
});

test("non serialization errors are not retried and keep the generic handling", async () => {
  let calls = 0;
  const db = {
    $transaction: async () => {
      calls++;
      throw { code: "P2002" };
    },
  } as unknown as PrismaClient;
  await assert.rejects(
    transaction(db, async () => 1),
    ConflictException,
  );
  assert.equal(calls, 1);
});
