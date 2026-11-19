import assert from "node:assert/strict";
import { test } from "node:test";
import { gradeLevelOf } from "../src/modules/recognition/domain/grade-level.js";

test("grade level: agreeing channels are green, a suggested channel is yellow, anything else red", () => {
  assert.equal(gradeLevelOf("KHOP", "SO"), "XANH");
  assert.equal(gradeLevelOf("KHOP", null), "XANH");
  assert.equal(gradeLevelOf("LECH", "CHU"), "VANG");
  assert.equal(gradeLevelOf("MOT_KENH", "SO"), "VANG");
  assert.equal(gradeLevelOf("LECH", null), "DO");
  assert.equal(gradeLevelOf("MOT_KENH", null), "DO");
  assert.equal(gradeLevelOf("KHONG_DOC_DUOC", null), "DO");
});
