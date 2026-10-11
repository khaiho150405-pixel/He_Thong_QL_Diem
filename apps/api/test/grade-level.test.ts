import assert from "node:assert/strict";
import { test } from "node:test";
import { gradeLevelOf } from "../src/modules/recognition/domain/grade-level.js";

test("grade level: agreeing channels are green, a suggested channel is yellow, anything else red", () => {
  assert.equal(gradeLevelOf("KHOP", "SO"), "XANH");
  assert.equal(gradeLevelOf("KHOP", null), "XANH");
  // Chỉ một kênh đủ tin cậy (hai kênh lệch hoặc một kênh đọc được) → có kênh gợi ý → Vàng.
  assert.equal(gradeLevelOf("LECH", "CHU"), "VANG");
  assert.equal(gradeLevelOf("MOT_KENH", "SO"), "VANG");
  // Cả hai mạnh mâu thuẫn, cả hai yếu, hoặc không kênh nào đọc được → không gợi ý → Đỏ.
  assert.equal(gradeLevelOf("LECH", null), "DO");
  assert.equal(gradeLevelOf("MOT_KENH", null), "DO");
  assert.equal(gradeLevelOf("KHONG_DOC_DUOC", null), "DO");
});
