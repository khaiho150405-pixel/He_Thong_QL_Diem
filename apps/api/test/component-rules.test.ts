import { test } from "node:test";
import assert from "node:assert/strict";
import { ConflictException } from "@nestjs/common";
import type { Unit } from "../src/common/store.js";
import { validateComponent } from "../src/modules/subjects/application/rules.js";

const previous = {
  ma_mon: 1,
  ten_thanh_phan: "Giữa kỳ",
  he_so: { toString: () => "2" },
  bat_buoc: true,
  thu_tu_hien_thi: 1,
  cho_phep_nhap: true,
};
const used = { count: async () => 1 } as unknown as Unit;

test("used component allows toggling input with an equivalent decimal weight", async () => {
  await validateComponent(
    used,
    {
      ...previous,
      he_so: "2.00",
      cho_phep_nhap: false,
    },
    previous,
  );
});

test("used component still rejects weight and structural changes", async () => {
  for (const change of [
    { he_so: "3.00" },
    { ma_mon: 2 },
    { bat_buoc: false },
  ]) {
    await assert.rejects(
      validateComponent(
        used,
        {
          ...previous,
          he_so: "2.00",
          ...change,
        },
        previous,
      ),
      ConflictException,
    );
  }
});
