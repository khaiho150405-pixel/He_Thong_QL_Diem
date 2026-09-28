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
